import {observedEpisodeMetadata} from '../scrapers/shared/episode-metadata.mjs';
// Beta-owned source-index parser; independent from canonical harvesting.
import * as cheerio from 'cheerio';
import {explicitEpisode,contentIdentity,identityDigits,explicitSeason} from '../../shared/content-identity.js';
import {resolveSafeUrl,assertSafeScraperUrl} from '../scrapers/shared/http.mjs';
import {identityTitle} from '../scrapers/content-discovery.mjs';
import {createHash} from 'node:crypto';
export const shortHash=value=>createHash('sha256').update(String(value)).digest('hex').slice(0,24);
export function referenceUrl(ref,domains){
 let text=String(ref||'');if(!text.startsWith('https://'))text=text.replace(/^[a-z0-9_-]+:/i,'');
 if(!text.startsWith('https://')&&!text.startsWith('/')){try{text=Buffer.from(text,'base64url').toString('utf8')}catch{throw Error('HARVEST_BAD_REFERENCE')}}
 const u=new URL(text,'https://'+domains[0]);assertSafeScraperUrl(u.href,{allowHttp:false,allowedHosts:domains});return u.href;
}
function safePage(raw,base,domains){const url=resolveSafeUrl(raw,base,{allowHttp:false,allowedHosts:domains});if(!url)return null;const u=new URL(url);if(u.hash||u.username||u.password)return null;return url}
const cleanTitle=x=>identityTitle(x).replace(/^(?:انمي|أنمي|anime)\s+/i,'').replace(/[أإآ]/g,'ا');
/** Observed links only. Never synthesize a guessed page count or number range. */
export function scanEpisodeIndex(html,url,{provider,domains,title='',episodes=[],seasonLinks=[]}={}){
 const $=cheerio.load(html);const byRef=new Map();const parentSeason=explicitSeason(title,url);
 const metadataByUrl=new Map();
 function ownsCard(parent,target){
  const pending=[parent[0]];let visited=0,links=0;
  while(pending.length){const node=pending.pop();if(++visited>64||(node.children?.length||0)>64)return false;
   if(node.name==='a'&&node.attribs?.href){const href=safePage(node.attribs.href,url,domains);if(href){if(href!==target||++links>4)return false;}}
   for(const child of node.children||[])pending.push(child);
  }
  return links>0;
 }
 // Enrich only an already-observed exact episode URL. A card spanning different
 // episodes must never donate the first image/time to all of them.
 $('a[href]').each((_,el)=>{
  const a=$(el),target=safePage(a.attr('href'),url,domains);if(!target)return;
  let card=a;const parent=a.closest('li,.thumbnail,.episode-tile,.episode-card,.episode,.ep-item,.video-item,.sh-episode-tile');
  if(parent.length&&ownsCard(parent,target))card=parent;
  const image=card.find('img').first();
  const observed=observedEpisodeMetadata({poster:image.attr('data-echo')||image.attr('data-src')||image.attr('src')||'',duration:a.attr('data-duration')||card.attr('data-duration')||card.find('time[datetime]').attr('datetime')||card.find('.pm-label-duration,.duration,.video-time,.episode-duration').first().text().trim()},url);
  if(Object.keys(observed).length)metadataByUrl.set(target,{...metadataByUrl.get(target),...observed});
 });
 function add(raw){
  let candidate=raw.url||raw.link||'';if(!candidate&&raw.ref){try{candidate=referenceUrl(raw.ref,domains)}catch{return}}
  const target=safePage(candidate,url,domains);if(!target)return;
  const text=String(raw.title||raw.name||'').trim().slice(0,500);const number=explicitEpisode(text,target)||Number(raw.episode_number??raw.number??raw.num);
  if(!Number.isSafeInteger(number)||number<1||number>100000)return;
  const season=Number(raw.season_number??raw.season)||explicitSeason(text,target)||parentSeason||1;
  const ref=raw.ref||provider+':'+Buffer.from(target).toString('base64url');
  byRef.set(target,{...byRef.get(target),...metadataByUrl.get(target),...observedEpisodeMetadata(raw,url),source_ref:ref,url:target,title:text||'الحلقة '+number,season,episode:number});
 }
 for(const row of episodes)add(row);
 $('.sh-single-episode-grid a[href],.EpisodesList a[href],.episodes-list a[href],.episodes-grid a[href],.episodes a[href],a.episode-tile[href],a.br-series-detail-card-link[href]').each((_,el)=>{
  const a=$(el), card=a.closest('.episode-tile,.thumbnail,.episode,.episode-card,.sh-episode-tile').length?a.closest('.episode-tile,.thumbnail,.episode,.episode-card,.sh-episode-tile'):a;const image=card.find('img').first();add({poster:image.attr('data-echo')||image.attr('data-src')||image.attr('src')||'',duration:card.find('time[datetime]').attr('datetime')||card.find('.pm-label-duration,.duration,.video-time,.episode-duration').first().text().trim(),url:a.attr('href'),title:a.find('.sh-episode-tile-title,.episode-title,.ep-title').first().text()||a.attr('title')||a.text(),number:a.attr('data-episode'),season:a.attr('data-season')});
 });
 const pages=new Set();
 const current=new URL(url);const page=Number(current.searchParams.get('page')||current.searchParams.get('paged')||current.searchParams.get('p'))||Number(current.pathname.match(/\/page\/(\d+)/)?.[1])||1;
 $('a[rel="next"][href],.pagination a[href],a.page-numbers[href],.page-numbers a[href],.sh-pagination a[href],.episodes-pagination a[href]').each((_,el)=>{
  const a=$(el),next=safePage(a.attr('href'),url,domains);if(!next||next===url)return;const n=new URL(next);
  const number=Number(n.searchParams.get('page')||n.searchParams.get('paged')||n.searchParams.get('p'))||Number(n.pathname.match(/\/page\/(\d+)/)?.[1])||null;
  const samePath=n.pathname.replace(/\/page\/\d+\/?$/,'/')===current.pathname.replace(/\/page\/\d+\/?$/,'/');
  if(samePath&&((number&&number>page)||a.attr('rel')==='next'||/التالي|Next/i.test(a.text())))pages.add(next);
 });
 const parents=new Set();
 // 5TV labels its observed parent link "return to drama", not the work title.
 if(provider==='fivetv')$('a.ftv-episode-poster-back[href]').each((_,el)=>{
  const parent=safePage($(el).attr('href'),url,domains);
  if(parent&&/^\/series\/[^/]+\/?$/.test(new URL(parent).pathname))parents.add(parent);
 });
 $('.br-series-detail-breadcrumb a[href],.breadcrumbs a[href],.breadcrumb a[href],.sh-single-breadcrumb a[href],.sh-single-info a[href],.episode-parent a[href],a[rel="up"][href]').each((_,el)=>{
  const a=$(el),href=safePage(a.attr('href'),url,domains);if(!href||href===url)return;
  if(/series|serie|season|مسلسل|انمي|anime/i.test(new URL(href).pathname)&&title&&cleanTitle(a.text())===cleanTitle(title))parents.add(href);
 });
 for(const link of seasonLinks){
  const parent=safePage(link.url,url,domains);
  const edition=t=>/مدبلج|dubbed/i.test(t)?'dubbed':/مترجم|subtit/i.test(t)?'subtitled':null;
  if(parent&&parent!==url&&Number.isSafeInteger(link.season)&&link.season>0&&cleanTitle(link.title)===cleanTitle(title)&&(!edition(title)||!edition(link.title)||edition(title)===edition(link.title)))parents.add(parent);
 }
 // AnimeZid groups provider-owned editions behind explicit season URLs. Its
 // "latest episodes" rail is not season one and must not create false numbering.
 if(provider==='animezid'){
  const root=current.pathname.match(/^\/series\/([^/]+)\/$/);
  if(root){
   const owned=new Set();
   $('a[href]').each((_,el)=>{const next=safePage($(el).attr('href'),url,domains);if(!next)return;
    const path=new URL(next).pathname.match(/^\/series\/([^/]+)\/season\/(\d+)\/$/);
    if(path&&path[1]===root[1]&&Number(path[2])>0)owned.add(next);
   });
   if(owned.size){byRef.clear();for(const next of owned)pages.add(next);}
  }
 }
 const declared=identityDigits($('.br-series-stats').text()).match(/(\d{1,5})\s*(?:حلقات|حلقة)/)?.[1]||identityDigits($('.anime-info').text()).match(/عدد الحلقات\s*:\s*(\d{1,5})/)?.[1];
 return {source_declared_references:declared?Number(declared):null,episodes:[...byRef.values()],pages:[...pages],parents:[...parents],page_fingerprint:shortHash([...byRef.keys()].sort().join('\n')),declared_title:$('h1').first().text().trim()};
}
