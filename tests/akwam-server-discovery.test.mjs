import test from 'node:test';
import assert from 'node:assert/strict';
import * as main from '../server/scrapers/sites/akwam.mjs';
import * as beta from '../server/browser/providers/sites/akwam.mjs';
import {resolveProviderMedia} from '../server/scrapers/shared/provider-media.mjs';

const root='https://akwam.ss/movie/42/observed';
const fixtures={
 [root]:'<h1>Movie</h1><video><source src="https://cdn.example/dead.mp4"></video>'+Array.from({length:8},(_,n)=>`<a href="https://akwam.ss/watch/quality-${n}">${n}p</a>`).join(''),
 ...Object.fromEntries(Array.from({length:8},(_,n)=>[`https://akwam.ss/watch/quality-${n}`,`<video><source src="https://cdn.example/quality-${n}.mp4" size="${n}"></video>`])),
};

for(const [name,provider]of [['main',main],['beta',beta]]){
 test(`${name} Akwam retains later observed qualities even when the page already contains a direct link`,async()=>{
  const servers=await provider.scrapeServers(root,{fixtures});
  assert.equal(servers._meta.bridge_targets,8);assert.equal(servers._meta.bridge_attempted,8);assert.equal(servers._meta.server_scan_complete,true);
  assert(servers.some(s=>s.url==='https://cdn.example/quality-7.mp4'));
  const resolved=await resolveProviderMedia({module:{scrapeServers:()=>provider.scrapeServers(root,{fixtures})}},root,{accept:async rows=>rows.filter(s=>s.url==='https://cdn.example/quality-7.mp4')});
  assert.equal(resolved.length,1);assert.equal(resolved[0].url,'https://cdn.example/quality-7.mp4');
 });
 test(`${name} Akwam exposes an incomplete bounded scan rather than false absence`,async()=>{
  const servers=await provider.scrapeServers(root,{fixtures,maxBridgeTargets:4});
  assert.equal(servers._meta.bridge_targets,8);assert.equal(servers._meta.bridge_attempted,4);assert.equal(servers._meta.server_scan_complete,false);
  await assert.rejects(resolveProviderMedia({module:{scrapeServers:()=>provider.scrapeServers(root,{fixtures,maxBridgeTargets:4})}},root,{accept:async()=>[]}),error=>error.code==='MEDIA_SERVER_SCAN_PARTIAL');
 });
 test(`${name} Akwam primary resolver retains the alternative source list for downstream failover`,async()=>{
  const resolved=await provider.resolveStream(root,{fixtures});
  assert.equal(resolved.url,'https://cdn.example/dead.mp4');
  assert(resolved.servers.some(s=>s.url==='https://cdn.example/quality-7.mp4'));
 });
}
