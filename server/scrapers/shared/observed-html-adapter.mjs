import * as cheerio from 'cheerio';
import {fetchProviderHtml, assertSafeScraperUrl, resolveSafeUrl} from './http.mjs';
import {effectiveProviderDomains} from './provider-config.mjs';
import {normalizeCatalogItem, normalizeDetailsResult, normalizeEpisodeList, normalizeServerList, extractEpisodeNumber, extractSeasonNumber, extractYear, inferContentType} from './normalize.mjs';
import {attachResultMeta,ScraperError,SCRAPER_ERROR_CODES} from './errors.mjs';
import {extractRawStreamsFromText, isValidDirectMediaUrl, cascadeResolveStream} from '../stream-unwrapper.mjs';

// This family owns its parser. Other families have their own implementation.
export function createObservedHtmlAdapter(meta, config) {
  const hosts = () => effectiveProviderDomains(meta.id, meta.domains.map(u => new URL(u).hostname));
  const base = () => 'https://' + hosts()[0];
  const refFor = url => meta.id + ':' + Buffer.from(url).toString('base64url');
  const context = url => ({providerId:meta.id, baseUrl:url, allowHttp:false});
  function target(value) {
    let raw = String(value || '');
    if (raw.length > 4096 || /[\x00-\x20\\]/.test(raw)) throw Error('INVALID_SOURCE_REFERENCE');
    if (raw.startsWith(meta.id + ':')) { raw=raw.slice(meta.id.length+1); if (!raw.startsWith('https://') && !raw.startsWith('/')) raw=Buffer.from(raw,'base64url').toString('utf8'); }
    const url = assertSafeScraperUrl(new URL(raw,base()).href,{allowHttp:false,allowedHosts:hosts()});
    if (!config.workPath.test(decodeURI(url.pathname))) throw Error('INVALID_SOURCE_REFERENCE');
    return url.href;
  }
  async function page(url,options={}) {
    const response = await fetchProviderHtml(url,{...options,providerId:meta.id,allowedHosts:hosts(),allowHttp:false,
      timeoutMs:Math.min(options.timeoutMs || 8000,10000),maxBytes:3*1024*1024,maxRetries:0});
    if (!response.ok) throw Error('SOURCE_HTTP_'+response.status);
    if (/\/(?:login|signin)(?:\/|$)/.test(new URL(response.url).pathname)) throw Error('SOURCE_LOGIN_REQUIRED');
    return response;
  }
  function parseCatalog(html,url=base()) {
    const $=cheerio.load(html), rows=[], seen=new Set();
    $(config.cards).each((_,node)=>{
      const card=$(node), a=card.is('a')?card:card.find(config.link || 'a[href]').first();
      let href; try { href=target(resolveSafeUrl(a.attr('href') || '',url,{allowHttp:false,allowedHosts:hosts()})); } catch { return; }
      if(seen.has(href))return;seen.add(href);
      const img=card.find('img').first(), title=card.find(config.cardTitle).first().text().trim() || a.attr('title') || img.attr('alt') || a.attr('aria-label') || '';
      if(!title)return;
      const item=normalizeCatalogItem({ref:refFor(href),url:href,title,poster:img.attr('data-src')||img.attr('src')||'',
        year:extractYear(title),type:/\/series\/|\/tv\//.test(new URL(href).pathname)?'series':inferContentType(title,href,config.defaultType || 'movie')},context(url));
      if(item)rows.push(item);
    });
    const next=resolveSafeUrl($('a[rel=next],.pagination a.next,.pagination .active + li a').first().attr('href')||'',url,{allowHttp:false,allowedHosts:hosts()});
    const n=next?Number(new URL(next).searchParams.get('page')||new URL(next).pathname.match(/\/page\/(\d+)/)?.[1]):null;
    return attachResultMeta(rows,{ok:true,providerId:meta.id,url,next_page:Number.isSafeInteger(n)&&n>1?n:null,next_url:next||null});
  }
  async function scrapeCatalog(category='latest',n=1,options={}) {
    if(!Number.isInteger(n)||n<1||n>500)throw Error('INVALID_SOURCE_PAGE');
    const path=config.categories[category];if(!path)throw Error('SOURCE_UNKNOWN_CATEGORY');
    let url=new URL(path,base());
    if(n>1){if(!options.searchPageUrl)throw Error('SOURCE_OBSERVED_NEXT_PAGE_REQUIRED');url=assertSafeScraperUrl(options.searchPageUrl,{allowHttp:false,allowedHosts:hosts()});}
    const result=await page(url.href,options);return parseCatalog(result.html,result.url);
  }
  async function scrapeSearch(query,n=1,options={}) {
    const q=String(query||'').trim();if(q.length<2||q.length>120)return[];
    if(!Number.isInteger(n)||n<1||n>500)throw Error('INVALID_SOURCE_PAGE');
    let url=new URL(config.searchPath,base());url.searchParams.set(config.queryParam,q);
    if(n>1){if(!options.searchPageUrl)throw Error('SOURCE_OBSERVED_NEXT_PAGE_REQUIRED');url=assertSafeScraperUrl(options.searchPageUrl,{allowHttp:false,allowedHosts:hosts()});}
    const result=await page(url.href,options);return parseCatalog(result.html,result.url);
  }
  function parseDetails(html,url) {
    const $=cheerio.load(html), title=$(config.detailTitle || 'h1').first().text().trim();
    if(!title)throw Error('SOURCE_DETAILS_STRUCTURE_CHANGED');
    const seasons=[];
    if(meta.id==='animezid' && /^\/series\/[^/]+\/$/.test(new URL(url).pathname))$('a[href*="/season/"]').each((_,e)=>{
      const href=resolveSafeUrl($(e).attr('href')||'',url,{allowHttp:false,allowedHosts:hosts()});
      const number=href?Number(new URL(href).pathname.match(/\/season\/(\d+)\/$/)?.[1]):null;
      if(href&&number&&new URL(href).pathname===new URL(url).pathname+'season/'+number+'/')seasons.push({url:href,season:number,title:$(e).text().trim()});
    });
    const episodes=[];
    if(!seasons.length)$(config.episodes).each((_,e)=>{
      const a=$(e), href=resolveSafeUrl(a.attr('href')||'',url,{allowHttp:false,allowedHosts:hosts()}), label=a.attr('title')||a.text().trim();
      const number=extractEpisodeNumber(label,href);if(!href||!number)return;
      try{target(href)}catch{return}
      episodes.push({ref:refFor(href),url:href,title:label,number,season:extractSeasonNumber(label,Number(new URL(url).pathname.match(/\/season\/(\d{1,3})\/?$/i)?.[1])||extractSeasonNumber(title+' '+url,1))});
    });
    const series=seasons.length>0 || episodes.length>0 || /\/series\/|\/tv\//.test(new URL(url).pathname) || /مسلسل|الحلقة|الحلقه|الموسم/.test(title);
    let declared=null;
    $('script[type="application/ld+json"]').each((_,node)=>{
      const text=$(node).html()||'';if(text.length>65536)return;
      try{const value=JSON.parse(text);for(const row of (Array.isArray(value['@graph'])?value['@graph']:[value])){
        const own=resolveSafeUrl(row.url||row['@id']||'',url,{allowHttp:false,allowedHosts:hosts()});
        if(own&&new URL(own).pathname===new URL(url).pathname&&['TVSeries','TVSeason'].includes(row['@type'])&&Number.isSafeInteger(row.numberOfEpisodes)&&row.numberOfEpisodes>0&&row.numberOfEpisodes<=100000)declared=row.numberOfEpisodes;
      }}catch{}
    });
    const normalized=normalizeDetailsResult({ref:refFor(url),sourceUrl:url,title,year:extractYear(title),
      poster:$('meta[property="og:image"]').attr('content')||'',overview:$(config.overview).first().text().trim(),
      type:series?'series':'movie',episodes:normalizeEpisodeList(episodes,context(url)),servers:[]},context(url));
    return {...normalized,season_links:seasons,source_season_links:seasons,declared_episode_count:declared,source_index_partial:series&&(declared===null||episodes.length<declared||seasons.length>0)};
  }
  async function scrapeDetails(ref,options={}){
    const r=await page(target(ref),options), details=parseDetails(r.html,r.url);
    if(meta.id!=='animezid'||new URL(r.url).pathname!=='/watch.php')return details;
    const $=cheerio.load(r.html), breadcrumb=$('nav.az-cinema-breadcrumb');
    const parent=resolveSafeUrl(breadcrumb.find('a[href*="/series/"]').first().attr('href')||'',r.url,{allowHttp:false,allowedHosts:hosts()});
    const seasonLink=resolveSafeUrl(breadcrumb.find('a[href*="/season/"]').first().attr('href')||'',r.url,{allowHttp:false,allowedHosts:hosts()});
    const number=extractEpisodeNumber(details.title,r.url), season=seasonLink?Number(new URL(seasonLink).pathname.match(/\/season\/(\d+)\/$/)?.[1]):null;
    if(!parent||!/^\/series\/[^/]+\/$/.test(new URL(parent).pathname)||!number||!season||new URL(seasonLink).pathname!==new URL(parent).pathname+'season/'+season+'/')return details;
    const p=await page(target(parent),options), root=parseDetails(p.html,p.url);
    return {...root,requested_source_ref:refFor(r.url),observed_parent_ref:refFor(p.url),requested_episode_title:details.title,
      episodes:[{ref:refFor(r.url),url:r.url,title:details.title,number,season}],source_index_partial:true};
  }
  async function scrapeEpisodes(ref,options={}){return (await scrapeDetails(ref,options)).episodes;}
  async function scrapeServers(ref,options={}) {
    let result=await page(target(ref),options), $=cheerio.load(result.html);
    if(meta.id==='movizland' && $('#WatchForm[method="POST"],#WatchForm[method="post"]').length){
      const form=$('#WatchForm'), action=target(resolveSafeUrl(form.attr('action')||'',result.url,{allowHttp:false,allowedHosts:hosts()}));
      if(action!==target(ref)||form.find('input[name="view"]').attr('value')!=='1')throw Error('SOURCE_WATCH_FORM_CHANGED');
      result=await page(action,{...options,method:'POST',body:'view=1',headers:{...options.headers,'content-type':'application/x-www-form-urlencoded'},referer:result.url});$=cheerio.load(result.html);
    }
    const play=$(config.playControl || 'a.__no_control__').first().attr('href');
    if(meta.id==='animezid' && !play){
      const watch=resolveSafeUrl($('.az-cinema-button--primary[href]').first().attr('href')||'',result.url,{allowHttp:false});
      if(watch && new URL(watch).origin!==new URL(result.url).origin && !isValidDirectMediaUrl(watch)){
        throw new ScraperError(SCRAPER_ERROR_CODES.UNSUPPORTED_CAPABILITY,'SOURCE_EXTERNAL_WATCH_GATEWAY',{providerId:meta.id});
      }
    }
    if(play){result=await page(target(resolveSafeUrl(play,result.url,{allowHttp:false,allowedHosts:hosts()})),options);$=cheerio.load(result.html);}
    const documents=[{html:result.html,url:result.url}];
    if(meta.id==='movizland' && !options.fixtureHtml){
      const observed=result.html.match(/url:\s*['"]([^'"\s]+\/servers\/server\.php)['"],\s*data:\s*['"]q=(\d{1,12})&i=/);
      if(observed && new URL(observed[1]).origin===new URL(result.url).origin){
        const ids=$('.serversList > li[data-server]').map((_,e)=>$(e).attr('data-server')).get().filter(id=>/^\d{1,2}$/.test(id)).slice(0,3);
        await Promise.all(ids.map(async id=>{
          const url=new URL(observed[1]);url.searchParams.set('q',observed[2]);url.searchParams.set('i',id);
          try{documents.push(await page(url.href,{...options,method:'GET',referer:result.url}));}catch{}
        }));
      }
    }
    const raw=[];
    for(const document of documents){
      const $=cheerio.load(document.html);
      raw.push(...extractRawStreamsFromText($(config.playerRegion).html()||'',document.url));

    $(config.frames).each((_,e)=>{
      const candidate=resolveSafeUrl($(e).attr('src')||$(e).attr('data-embed-url')||'',document.url,{allowHttp:false,allowedHosts:config.embedHosts});
      if(candidate)raw.push({url:candidate,type:'embed',verified:false});
    });
    }
    return attachResultMeta(normalizeServerList(raw,{...context(result.url),providerName:meta.name,codePrefix:meta.code}),{ok:raw.length>0,providerId:meta.id,url:result.url});
  }
  async function resolveStream(ref,options={}) {
    const servers=await scrapeServers(ref,options), direct=[];
    const deadline=Date.now()+12000;
    let cursor=0;
    const pending=servers;
    async function worker(){while(cursor<pending.length&&Date.now()<deadline){
      const server=pending[cursor++];
      if(isValidDirectMediaUrl(server.url))direct.push(server);
      else if(!options.fixtureHtml){try{direct.push(...await cascadeResolveStream(server.url,target(ref),0,new Set(),deadline))}catch{}}
    }}
    await Promise.all([worker(),worker()]);
    const safe=direct.filter(row=>isValidDirectMediaUrl(row.url)), primary=safe[0];
    return attachResultMeta({ok:!!primary,url:primary?.url||null,streamUrl:primary?.url||null,servers:safe,headers:primary?.headers||{}},{ok:!!primary,providerId:meta.id});
  }
  return {parseCatalog,parseDetails,decodeProviderRef:target,scrapeCatalog,scrapeSearch,scrapeDetails,scrapeEpisodes,scrapeServers,resolveStream};
}
