import * as cheerio from 'cheerio';
import {assertSafeScraperUrl,fetchProviderHtml,fetchSafeResponse,resolveSafeUrl} from '../shared/http.mjs';
import {normalizeCatalogItem,normalizeDetailsResult,normalizeEpisodeList,normalizeServerList} from '../shared/normalize.mjs';
import {attachResultMeta,ScraperError} from '../shared/errors.mjs';

const origin='https://www.atv.com.tr';
const siteHosts=['www.atv.com.tr','atv.com.tr'];
const cdnHosts=['httxxkbiqd.erbvr.com','httxxkbiqd.fdc.ercdn.net'];
const id='atv-tr';
export const PROVIDER_META = Object.freeze({id:'atv-tr',name:'ATV Türkiye',code:'ATVT',domains:[origin],mirrorOf:null,resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false}});
export const ATV_CONFIG=Object.freeze({categories:{series:'/diziler',archive:'/eski-diziler'},
  categoryLabels:{series:'المسلسلات الحالية',archive:'أرشيف المسلسلات'}});
const episodePath=/^\/([a-z0-9-]+)\/(\d+)-bolum(?:\/izle)?\/?$/;
const seriesPath=/^\/[a-z0-9-]+\/?$/;
const context=baseUrl=>({providerId:id,baseUrl,allowHttp:false});
const ref=url=>id+':'+Buffer.from(url).toString('base64url');
const text=value=>String(value||'').replace(/\s+/g,' ').trim();
const searchKey=value=>text(value).toLocaleLowerCase('tr-TR')
  .replace(/ı/g,'i').normalize('NFD').replace(/\p{M}/gu,'');

export function decodeProviderRef(value) {
  let raw=String(value||'');
  if (raw.startsWith(id+':')) {
    raw=raw.slice(id.length+1);
    if (!raw.startsWith('https://')) raw=Buffer.from(raw,'base64url').toString();
  }
  if (/^\/(?!\/)/.test(raw)) raw=new URL(raw,origin).href;
  const url=assertSafeScraperUrl(raw,{allowHttp:false,allowedHosts:siteHosts});
  if (!seriesPath.test(url.pathname) && !episodePath.test(url.pathname)) {
    throw new ScraperError('UNSAFE_URL','ATV_INVALID_REFERENCE',{providerId:id});
  }
  return url.origin+url.pathname;
}
async function load(url,options) {
  const result=await fetchProviderHtml(url,{...options,providerId:id,allowHttp:false,allowedHosts:siteHosts,
    timeoutMs:Math.min(options?.timeoutMs||6500,6500),maxRetries:1,maxBytes:2*1024*1024});
  if (!result.ok) throw new ScraperError('UPSTREAM_UNAVAILABLE','ATV_PAGE_UNAVAILABLE',{providerId:id,status:result.status});
  return result;
}

export async function scrapeCatalog(category='series',page=1,options={}) {
  if (!Object.hasOwn(ATV_CONFIG.categories,category)) throw Error('ATV_UNKNOWN_CATEGORY');
  if (page!==1) return attachResultMeta([],{ok:true,next_page:null});
  const {html,url}=await load(origin+ATV_CONFIG.categories[category],options);
  const $=cheerio.load(html);
  const items=new Map();
  $('.category-classic-item > a[href]').each((_,node)=>{
    const card=$(node);
    const target=resolveSafeUrl(card.attr('href'),url,{allowHttp:false,allowedHosts:siteHosts});
    const image=card.find('img').first();
    if (!target || !seriesPath.test(new URL(target).pathname)) return;
    const item=normalizeCatalogItem({url:target,ref:ref(target),title:text(image.attr('alt')||card.attr('title')),
      type:'series',poster:image.attr('data-src')||image.attr('src')},context(url));
    if (item) items.set(item.ref,item);
  });
  if (!items.size) throw new ScraperError('STRUCTURE_CHANGED','ATV_CATALOG_STRUCTURE_CHANGED',{providerId:id});
  return attachResultMeta([...items.values()],{ok:true,next_page:null,providerId:id});
}
export async function scrapeSearch(query,page=1,options={}) {
  const needle=searchKey(query);
  if (needle.length<2 || page!==1) return attachResultMeta([],{ok:true,next_page:null});
  const results=await Promise.allSettled(['series','archive'].map(category=>scrapeCatalog(category,1,options)));
  if (results.every(result=>result.status==='rejected')) throw results[0].reason;
  const rows=new Map();
  for (const result of results) if (result.status==='fulfilled') {
    for (const item of result.value) if (searchKey(item.title).includes(needle)) rows.set(item.ref,item);
  }
  return attachResultMeta([...rows.values()],{ok:true,next_page:null,partial:results.some(r=>r.status==='rejected')});
}

export async function scrapeDetails(value,options={}) {
  const target=decodeProviderRef(value);
  const slug=new URL(target).pathname.split('/')[1];
  const {html,url}=await load(new URL('/'+slug+'/bolumler',origin).href,options);
  const $=cheerio.load(html);
  const heading=text($('h1').first().text() || $('meta[property="og:title"]').attr('content'));
  const title=heading.replace(/\s+(?:DİZİSİ|Dizisi|dizisi)$/u,'');
  if (!title) throw new ScraperError('STRUCTURE_CHANGED','ATV_DETAILS_STRUCTURE_CHANGED',{providerId:id});
  const episodes=[];
  $('a[href*="-bolum"]').each((_,node)=>{
    const target=resolveSafeUrl($(node).attr('href'),url,{allowHttp:false,allowedHosts:siteHosts});
    if (!target) return;
    const match=episodePath.exec(new URL(target).pathname);
    if (match?.[1]!==slug) return;
    const playback=new URL('/'+slug+'/'+match[2]+'-bolum/izle',origin).href;
    episodes.push({url:playback,ref:ref(playback),number:Number(match[2])});
  });
  const work=new URL('/'+slug,origin).href;
  return normalizeDetailsResult({sourceUrl:work,ref:ref(work),title,type:'series',
    poster:$('meta[property="og:image"]').attr('content'),
    episodes:normalizeEpisodeList(episodes,context(url))},context(url));
}
export async function scrapeEpisodes(value,options={}) { return (await scrapeDetails(value,options)).episodes; }

export async function scrapeServers(value,options={}) {
  const target=decodeProviderRef(value);
  if (!episodePath.test(new URL(target).pathname)) return [];
  const {html,url}=await load(target,options);
  const $=cheerio.load(html);
  const media=[];
  for (const node of $('script[type="application/ld+json"]').toArray()) {
    let data;
    try { data=JSON.parse($(node).text()); } catch { continue; }
    if (data?.['@type']!=='VideoObject') continue;
    const target=resolveSafeUrl(data.contentUrl,url,{allowHttp:false,allowedHosts:cdnHosts});
    if (!target || !new URL(target).pathname.endsWith('.mp4')) continue;
    media.push({url:target,type:'mp4',label:'ATV',quality:new URL(target).pathname.match(/(?:720|1080|2160)p/i)?.[0]||'تلقائي',
      headers:{Referer:url}});
  }
  return normalizeServerList(media,{...context(url),providerName:'ATV',codePrefix:'ATVT'});
}
export async function resolveStream(value,options={}) {
  const servers=[];
  for (const stream of await scrapeServers(value,options)) {
    try {
      const result=await fetchSafeResponse(stream.url,{allowHttp:false,allowedHosts:cdnHosts,
        headers:{...stream.headers,Range:'bytes=0-1023'},responseType:'bytes',prefixBytes:1024,
        maxBytes:4096,timeoutMs:6500,maxRetries:0,maxRedirects:5,
        ...(options.fetchImpl ? {fetchImpl:options.fetchImpl} : {})});
      if (result.ok && Buffer.from(result.bytes||[]).subarray(4,8).toString()==='ftyp') servers.push(stream);
    } catch {}
  }
  const first=servers[0];
  return attachResultMeta({ok:Boolean(first),url:first?.url??null,streamUrl:first?.url??null,
    streamType:first?.streamType??null,headers:first?.headers??{},servers},
  {ok:Boolean(first),providerId:id,errorCode:first?null:'SERVER_EXTRACTION_FAILED'});
}
