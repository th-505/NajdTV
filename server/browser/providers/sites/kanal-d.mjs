import * as cheerio from 'cheerio';
import {assertSafeScraperUrl,fetchProviderHtml,fetchSafeResponse,resolveSafeUrl} from '../../../scrapers/shared/http.mjs';
import {normalizeCatalogItem,normalizeDetailsResult,normalizeEpisodeList,normalizeServerList} from '../../../scrapers/shared/normalize.mjs';
import {attachResultMeta,ScraperError} from '../../../scrapers/shared/errors.mjs';

const origin='https://www.kanald.com.tr';
const siteHosts=['www.kanald.com.tr','kanald.com.tr'];
const cdnHosts=['kanaldvod.duhnet.tv'];
const id='kanal-d';
export const PROVIDER_META = Object.freeze({id:'kanal-d',name:'Kanal D',code:'KND',domains:[origin],mirrorOf:null,resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false}});
export const KND_CONFIG=Object.freeze({categories:{series:'/diziler',archive:'/diziler/arsiv'},
  categoryLabels:{series:'المسلسلات الحالية',archive:'أرشيف المسلسلات'}});
const episodePath=/^\/([a-z0-9-]+)\/bolumler\/(?:\1-)?(\d+|ilk)-bolum(?:-izle)?\/?$/;
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
    throw new ScraperError('UNSAFE_URL','KND_INVALID_REFERENCE',{providerId:id});
  }
  return url.origin+url.pathname;
}
async function load(url,options) {
  const result=await fetchProviderHtml(url,{...options,providerId:id,allowHttp:false,allowedHosts:siteHosts,
    timeoutMs:Math.min(options?.timeoutMs||6500,6500),maxRetries:1,maxBytes:2*1024*1024});
  if (!result.ok) throw new ScraperError('UPSTREAM_UNAVAILABLE','KND_PAGE_UNAVAILABLE',{providerId:id,status:result.status});
  return result;
}

export async function scrapeCatalog(category='series',page=1,options={}) {
  if (!Object.hasOwn(KND_CONFIG.categories,category)) throw Error('KND_UNKNOWN_CATEGORY');
  if (page!==1) return attachResultMeta([],{ok:true,next_page:null});
  const {html,url}=await load(origin+KND_CONFIG.categories[category],options);
  const $=cheerio.load(html);
  const items=new Map();
  for (const node of $('a.poster-card[href]').toArray()) {
    const anchor=$(node);
    const target=resolveSafeUrl(anchor.attr('href'),url,{allowHttp:false,allowedHosts:siteHosts});
    if (!target || !seriesPath.test(new URL(target).pathname)) continue;
    const poster=anchor.find('img').first();
    const title=text(poster.attr('alt')||anchor.attr('title'));
    const item=normalizeCatalogItem({ref:ref(target),url:target,title,type:'series',poster:poster.attr('data-src')||poster.attr('src')},context(url));
    if (item) items.set(item.ref,item);
  }
  if (!items.size) throw new ScraperError('STRUCTURE_CHANGED','KND_CATALOG_STRUCTURE_CHANGED',{providerId:id});
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
  const heading=text($('meta[property="og:title"]').attr('content') || $('h1').first().text());
  const tabTitle=text($('title').first().text()).match(/^Bölümler\s+-\s+(.+)$/iu)?.[1];
  const title=tabTitle || heading.replace(/\s+Tüm Bölümler(?:\s*[(-].*)?$/iu,'');
  if (!title) throw new ScraperError('STRUCTURE_CHANGED','KND_DETAILS_STRUCTURE_CHANGED',{providerId:id});
  const episodes=[];
  const links=$('a[href]').toArray().map(node=>resolveSafeUrl($(node).attr('href'),url,{allowHttp:false,allowedHosts:siteHosts}));
  for (const target of new Set(links.filter(Boolean))) {
    const match=new URL(target).pathname.match(episodePath);
    if (!match || match[1]!==slug) continue;
    const playback=target;
    episodes.push({url:playback,ref:ref(playback),number:match[2] === 'ilk' ? 1 : Number(match[2])});
  }
  const work=new URL('/'+slug,origin).href;
  let poster=$('meta[property="og:image"]').attr('content');
  if (!poster && !options.fixtureHtml) {
    try {
      const workPage=await load(work,options);
      poster=cheerio.load(workPage.html)('meta[property="og:image"]').attr('content');
    } catch {}
  }
  return normalizeDetailsResult({sourceUrl:work,ref:ref(work),title,type:'series',poster,
    episodes:normalizeEpisodeList(episodes,context(url))},context(url));
}
export async function scrapeEpisodes(value,options={}) { return (await scrapeDetails(value,options)).episodes; }

function findVideo($) {
  const candidates=$('script[type="application/ld+json"]').toArray().map(node=>{
    try { return JSON.parse($(node).text()); } catch { return null; }
  });
  return candidates.find(row=>String(row?.['@type']).split('/').at(-1)==='VideoObject');
}
export async function scrapeServers(value,options={}) {
  const target=decodeProviderRef(value);
  if (!episodePath.test(new URL(target).pathname)) return [];
  const {html,url}=await load(target,options);
  const $=cheerio.load(html);
  const media=[];
  const video=findVideo($);
  const direct=typeof video?.contentUrl==='string' && video.contentUrl.startsWith('https://')
    ? resolveSafeUrl(video.contentUrl,url,{allowHttp:false,allowedHosts:cdnHosts}) : null;
  if (direct && /^\/hls\/.+\.m3u8$/i.test(new URL(direct).pathname)) {
    return normalizeServerList([{url:direct,type:'m3u8',label:'Kanal D',quality:'AUTO-HLS',headers:{Referer:url}}],
      {...context(url),providerName:'Kanal D',codePrefix:'KND'});
  }
  const embed = video?.embedUrl;
  const safeEmbed = resolveSafeUrl(embed,url,{allowHttp:false,allowedHosts:siteHosts});
  if (!safeEmbed || !/^\/embed\/[a-f0-9]{24}\/?$/i.test(new URL(safeEmbed).pathname)) return [];
  const response=await load(safeEmbed,options);
  const player=cheerio.load(response.html);
  const publishedBase=response.html.match(/MediaCdnDomainUrl\s*:\s*["'](https:\/\/[^"']+)["']/)?.[1];
  const data=findVideo(player);
  if (!publishedBase || !data?.contentUrl) return [];
  const mediaUrl=resolveSafeUrl(data.contentUrl,publishedBase+'/',{allowHttp:false,allowedHosts:cdnHosts});
  if (mediaUrl && /^\/(?:hls|S\d+\/HLS_VOD)\/.+\.m3u8$/i.test(new URL(mediaUrl).pathname)) {
    media.push({url:mediaUrl,type:'m3u8',label:'Kanal D',quality:'AUTO-HLS',headers:{Referer:response.url}});
  }
  return normalizeServerList(media,{...context(url),providerName:'Kanal D',codePrefix:'KND'});
}
export async function resolveStream(value,options={}) {
  const servers=[];
  for (const stream of await scrapeServers(value,options)) {
    try {
      const result=await fetchSafeResponse(stream.url,{allowHttp:false,allowedHosts:cdnHosts,
        headers:{...stream.headers,Range:'bytes=0-1023'},responseType:'bytes',prefixBytes:1024,
        maxBytes:4096,timeoutMs:6500,maxRetries:0,maxRedirects:5,
        ...(options.fetchImpl ? {fetchImpl:options.fetchImpl} : {})});
      if (result.ok && Buffer.from(result.bytes||[]).toString().trimStart().startsWith('#EXTM3U')) servers.push(stream);
    } catch {}
  }
  const first=servers[0];
  return attachResultMeta({ok:Boolean(first),url:first?.url??null,streamUrl:first?.url??null,
    streamType:first?.streamType??null,headers:first?.headers??{},servers},
  {ok:Boolean(first),providerId:id,errorCode:first?null:'SERVER_EXTRACTION_FAILED'});
}
