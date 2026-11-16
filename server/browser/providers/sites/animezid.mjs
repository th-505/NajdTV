import {createObservedHtmlAdapter} from '../shared/observed-html-adapter.mjs';
// Independent animezid source, public routes observed 2026-11-15.
export const PROVIDER_META = Object.freeze({id:'animezid',name:'أنمي زد',code:'AZ',domains:['https://animezid.org'],mirrorOf:null,resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false},
  searchSpec:{method:'GET',pathTemplate:'/search.php?keywords={query}',queryParam:'keywords'}});
export const SOURCE_CONFIG = Object.freeze({categories:{latest:'/',movies:'/category.php?cat=movies',series:'/category.php?cat=anime'},searchPath:'/search.php',queryParam:'keywords',
  cards:'.az-card,.az-showcase-card',cardTitle:'.az-card__title,.az-showcase-card__copy strong',workPath:/^\/(?:series\/[^/?]+(?:\/season\/\d+)?\/?|watch\.php|play\.php)$/,
  episodes:'.az-series-season-episode-grid a[href*="watch.php"]',overview:'.az-series-description,.az-watch-description',playerRegion:'#player,#video-player,.az-player',
  frames:'.az-player iframe[src],[data-embed-url]',embedHosts:['animezid.org'],playControl:'a[href*="play.php?vid="]'});
const adapter=createObservedHtmlAdapter(PROVIDER_META,SOURCE_CONFIG);
export const decodeProviderRef=adapter.decodeProviderRef;
export const parseCatalog=adapter.parseCatalog;
export const parseDetails=adapter.parseDetails;
export async function scrapeCatalog(category='latest',page=1,options={}){return adapter.scrapeCatalog(category,page,options);}
export async function scrapeSearch(query,page=1,options={}){return adapter.scrapeSearch(query,page,options);}
export async function scrapeDetails(ref,options={}){return adapter.scrapeDetails(ref,options);}
export async function scrapeEpisodes(ref,options={}){return adapter.scrapeEpisodes(ref,options);}
export async function scrapeServers(ref,options={}){return adapter.scrapeServers(ref,options);}
export async function resolveStream(ref,options={}){return adapter.resolveStream(ref,options);}
