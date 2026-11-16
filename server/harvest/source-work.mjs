import {sourceIndexIdentity} from './source-edition-identity.mjs';
import {workReference,providerForReference,scraperReference} from './work-reference.mjs';
import {referenceUrl,scanEpisodeIndex,shortHash} from './episode-index.mjs';
import {decideSourceCatalog,compactCatalogDecision} from '../scrapers/shared/catalog-decision.mjs';
/** Each provider + actual series reference owns its index, including every dubbed cut. */
export function createSourceWorkHandler({store,entries,now,fetchPage,job}){
 return async input=>{
  const original=input.payload?.source_ref;if(!original||workReference(original)!==input.content_ref)throw Error('HARVEST_SOURCE_REFERENCE_CONFLICT');
  const id=providerForReference(original),entry=entries.get(id);if(!entry)throw Error('HARVEST_PROVIDER_UNAVAILABLE');
  const domains=entry.meta.domains.map(d=>new URL(d).hostname),ref=scraperReference(original);
  let observedPage=null;
  const network={strict:true,allowHttp:false,timeoutMs:8000,maxRetries:0,onProviderPage:page=>{observedPage=page}};
  const page=input.payload.phase==='source_page';
  const details=await entry.module.scrapeDetails(page?input.payload.url:ref,network);if(!details?.title)throw Error('HARVEST_SOURCE_METADATA_MISSING');
  const target=referenceUrl(page?input.payload.url:details.sourceUrl||ref,domains);
  const html=observedPage?.url===target&&typeof observedPage.html==='string' ? observedPage.html : (await fetchPage(target,{...network,providerId:id,allowedHosts:domains})).html;
  const index=scanEpisodeIndex(html,target,{provider:id,domains,title:details.title,episodes:details.episodes||[],seasonLinks:details.source_season_links||[]});
  if(page&&input.payload.seen_fingerprints?.includes(index.page_fingerprint))return{progress:{outcome:'partial',reason:'PAGINATION_REPEATED'}};
  const indexStarted=page?input.payload.catalog_started_at:input.started_at||new Date(now()).toISOString();
  const prior=[];if(page){let offset=0;while(true){const rows=await store.episodes(input.content_ref,{offset,limit:1000,indexedSince:indexStarted});prior.push(...rows);if(rows.length<1000)break;offset+=1000;}}
  const merged=[...new Map([...prior,...index.episodes].map(row=>[row.source_ref,row])).values()];
  const root=input.payload.root_metadata?.source_ref===original?input.payload.root_metadata:null;
  const display=root?{...details,...root}:details;
  const rootMetadata=root||{source_ref:original,title:details.title,originalTitle:details.originalTitle||'',type:details.type,poster:details.poster||'',overview:String(details.overview||details.story||'').slice(0,4000),year:details.year||null};
  const analysis=decideSourceCatalog({...display,episodes:merged},{pendingPages:index.pages.length});
  const report=compactCatalogDecision(analysis);
  const series=display.type!=='movie',workRef=input.content_ref,stamp=new Date(now()).toISOString();
  const canonical=input.payload.canonical_ref?await store.getWork(input.payload.canonical_ref):null;
  const sourceSeasons=analysis.index.seasons.map(s=>({season_number:s.season,episode_count:s.distinct_episodes,name:'الموسم '+s.season}));
  const metadata={title:display.title,poster:display.poster||'',overview:String(display.overview||display.story||'').slice(0,4000),year:display.year||null,type:series?'series':'movie',provider:id,source_ref:original,identity_scope:'source',source_edition:analysis.edition,edition:id+':'+shortHash(original),runtime_minutes:analysis.runtime_minutes,source_index_authoritative:true,canonical_identity_verified:false,number_of_seasons:sourceSeasons.length,number_of_episodes:analysis.index.distinct_episodes,seasons:sourceSeasons,catalog_decision:report};
  metadata.index_started_at=indexStarted;
  metadata.index_identity=sourceIndexIdentity(id,analysis.edition,merged);
  metadata.source_domain=new URL(target).hostname;
  if(canonical?.metadata)metadata.catalog_metadata={ref:canonical.ref,title:canonical.metadata.title,poster:canonical.metadata.poster||'',overview:String(canonical.metadata.overview||'').slice(0,4000),year:canonical.metadata.year||null};
  await store.putWork({ref:workRef,tmdb_id:null,type:metadata.type,title:metadata.title,original_title:display.originalTitle||'',aliases:[],year:Number(display.year)||null,runtime_minutes:analysis.runtime_minutes,genres:details.genres||[],poster:metadata.poster,season_count:sourceSeasons.length,episode_count:analysis.index.distinct_episodes,metadata,state:'partial',last_requested_at:stamp,last_checked_at:stamp,expires_at:new Date(now()+7*86400000).toISOString(),updated_at:stamp});
  const rows=series?index.episodes:[{source_ref:original,season:0,episode:0,title:details.title}];
  await store.putEpisodes(rows.map(({source_ref,season,episode,title,poster,duration_seconds})=>({work_ref:workRef,provider:id,source_ref,season,episode,title,...(poster?{poster}:{}),...(duration_seconds?{duration_seconds}:{})})));
  await store.putSource({work_ref:workRef,provider:id,source_ref:original,identity_score:1,evidence:{scope:'source',canonical_identity_verified:false,title:details.title},state:index.pages.length?'partial':'indexed',progress:{source_work_ref:workRef,index_identity:metadata.index_identity,title:details.title,domain:new URL(target).hostname,edition:analysis.edition,seasons:sourceSeasons,catalog_decision:report},updated_at:stamp});
  if(input.payload.canonical_ref){
   await store.putSource({work_ref:input.payload.canonical_ref,provider:id,source_ref:original,identity_score:Number(input.payload.identity_score)||0,evidence:{...(input.payload.identity_evidence||{}),canonical_identity_verified:input.payload.canonical_identity_verified===true},state:input.payload.canonical_identity_verified?'indexed':'identity_unconfirmed',progress:{source_work_ref:workRef,index_identity:metadata.index_identity,title:details.title,domain:new URL(target).hostname,edition:analysis.edition,seasons:sourceSeasons,catalog_decision:report},updated_at:stamp});
  }
  const cycle=input.payload.cycle||input.started_at||stamp;
  const knownPages=new Set([...(input.payload.known_pages||[]),target]);
  const nextPages=[...new Set([...index.parents,...index.pages])].filter(next=>!knownPages.has(next));
  for(const next of nextPages)knownPages.add(next);
  // Persist the full source index; direct video is resolved on explicit playback demand.
  // Thousands of unsolicited episode jobs must never delay interactive discovery.
  for(const next of nextPages)await store.enqueueMany([job(workRef,id,'provider','source-page:'+next,{...input.payload,phase:'source_page',root_metadata:rootMetadata,known_pages:[...knownPages].slice(-2048),catalog_started_at:indexStarted,source_work_ref:workRef,url:next,source_ref:original,cycle,seen_fingerprints:[...(input.payload.seen_fingerprints||[]),index.page_fingerprint].slice(-32)},details.title)]);
  await store.event({work_ref:workRef,provider:id,stage:'catalog',outcome:rows.length?'source_indexed':'no_observed_episodes',reason:null,details:{edition:analysis.edition,source_seasons:sourceSeasons,observed_references:rows.length,pending_pages:index.pages.length,canonical_identity_verified:false}});
  return {progress:{outcome:'source_indexed',edition:analysis.edition,observed_episodes:rows.length,source_work_ref:workRef}};
 };
}
