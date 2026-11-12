import {randomUUID} from 'node:crypto';
import {createHarvestPipeline} from './pipeline.mjs';

// Catalog/index evidence is shared. Extraction results belong to this request:
// no shared media writes, pending-promise reuse, or invalidation of another viewer.
export function createSessionPlayback({store, entries, now=Date.now, probe}={}) {
  return async function resolve({work, row, season=0, episode=0, platform='native'}) {
    let media=[];
    const isolatedStore={
      getWork:async()=>work,
      getEpisode:async()=>null,
      setEpisode:async(_work,_provider,_source,patch)=>{if(patch.media)media=patch.media;},
      request:async()=>[], event:async()=>{},
    };
    const pipeline=createHarvestPipeline({store:isolatedStore,entries,now,probe});
    const evidence=row.media?.find(m=>m.source_identity)?.source_identity;
    await pipeline.episode({content_ref:work.ref,provider:row.provider,
      season_number:season,episode_number:episode,payload:{
        source_ref:row.source_ref,force_refresh:true,platform,
        observed_identity:{title:work.metadata.title,year:work.metadata.year||null},
        observed_episode:evidence||{season,episode,source_season:season,source_episode:episode,numbering_basis:'source-season'},
      }});
    const session=randomUUID();
    return media.filter(m=>Date.parse(m.expires_at)>now()+30000)
      .map(m=>({...m,playback_session:session,playback_scope:'request'}));
  };
}
