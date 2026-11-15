import {createObservedHtmlAdapter} from '../shared/observed-html-adapter.mjs';
// Independent movizland source, public routes observed 2026-11-15.
export const PROVIDER_META = Object.freeze({id:'movizland',name:'موفيز لاند',code:'ML',domains:['https://movizland.life'],mirrorOf:null,resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false},
  searchSpec:{method:'GET',pathTemplate:'/?s={query}',queryParam:'s'}});
export const SOURCE_CONFIG = Object.freeze({categories:{latest:'/',movies:'/category/افلام-اون-لاين/',series:'/category/مسلسلات-اون-لاين/'},searchPath:'/',queryParam:'s',
  cards:'.Block',cardTitle:'h2',workPath:/^\/(?!wp-|category|release-year|tag|author|page|search|admin|login|register|logout|account|feed|contact|about)[^/?]+\/$/,
  episodes:'.EpisodesList a[href],.List--Seasons--Episodes a[href],.Episodes--Seasons a[href]',overview:'.StoryMovieContent,.Story,.Description',playerRegion:'.WatchBody,#Player,.WatchContainer',
  frames:'iframe[src]',embedHosts:['stmruby.com','hgcloud.to','bysekoze.com','vidaraa.cc','morencius.com'],playControl:''});
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
