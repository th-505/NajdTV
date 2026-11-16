import {createObservedHtmlAdapter} from '../shared/observed-html-adapter.mjs';
// Independent egybest source, public routes observed 2026-11-15.
export const PROVIDER_META = Object.freeze({id:'egybest',name:'إيجي بست',code:'EB',domains:['https://egybe.st'],mirrorOf:null,resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false},
  searchSpec:{method:'GET',pathTemplate:'/search.php?keyword={query}',queryParam:'keyword'}});
export const SOURCE_CONFIG = Object.freeze({categories:{latest:'/',movies:'/movies',series:'/tv',anime:'/anime'},searchPath:'/search.php',queryParam:'keyword',
  cards:'a.postBlock,.postBlockCol a[href]',cardTitle:'h3.title',workPath:/^\/(?:movie|tv|episode)\/\d+\/[^/?]+\/?$/,
  episodes:'.episodesList a[href],.seasonEpisodes a[href],.episodes a[href]',overview:'.story,.movieStory,.description',playerRegion:'#contentHolder,#player,.player',
  frames:'iframe#contentHolder[src]',embedHosts:['movies2watchtv.live'],playControl:''});
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
