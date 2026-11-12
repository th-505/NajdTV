import {createConcurrencyQueue} from './scrapers/shared/concurrency.mjs';

// A random per-open capability identifies only one extraction. Never persist
// credentials or deduplicate work by the catalog reference alone.
export function createPlaybackSessions({now=Date.now,maxEntries=128,concurrency=3}={}){
 const jobs=new Map(),queue=createConcurrencyQueue({concurrency,maxQueued:12});
 return function request(session,identity,resolve){
  if(!/^[a-f0-9]{32}$/.test(session||''))throw Error('INVALID_PLAYBACK_SESSION');
  for(const [key,job] of jobs)if(job.expires<=now()&&job.state!=='running')jobs.delete(key);
  const key=JSON.stringify([session,identity]);let job=jobs.get(key);
  if(!job){
   if(jobs.size>=maxEntries)return {state:'unavailable',reason:'PLAYBACK_CAPACITY'};
   job={state:'running',expires:now()+120000};jobs.set(key,job);
   queue.run(resolve).then(servers=>{
    job.servers=servers.filter(s=>Date.parse(s.expires_at)>now()+30000);
    job.state=job.servers.length?'ready':'unavailable';
    job.reason=job.servers.length?null:'DIRECT_MEDIA_NOT_FOUND';
    job.expires=Math.min(now()+60000,...job.servers.map(s=>Date.parse(s.expires_at)-30000));
   },error=>{job.state='unavailable';job.reason=/^[A-Z][A-Z0-9_]{2,79}$/.test(error.code||error.message||'')?error.code||error.message:'SESSION_MEDIA_UNAVAILABLE';job.expires=now()+10000;});
  }
  return {state:job.state,...(job.state==='ready'?{servers:job.servers,cache_hit:false}:{}),
   ...(job.reason?{reason:job.reason}:{}),...(job.state==='running'?{poll_after_ms:1000}:{}),playback_session:session};
 };
}
