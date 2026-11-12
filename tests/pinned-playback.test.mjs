import test from 'node:test';
import assert from 'node:assert/strict';
import {createPinnedPlayback} from '../server/pinned-playback.mjs';
import {probeHarvestMedia} from '../server/harvest/media-probe.mjs';
const ref='mycima:'+Buffer.from('https://wecima.show/series/example/').toString('base64url');
const ep=n=>'mycima:'+Buffer.from('https://wecima.show/episode/'+n).toString('base64url');
const input={provider:'mycima',seriesRef:ref,type:'series',season:2,episode:4,platform:'web'};
const media={url:'https://media.example/movie.mp4',web_playable:true,kind:'direct'};
test('selects exact season and episode, not another season or first episode',async()=>{
 const calls=[];const runtime=createPinnedPlayback({loadDetails:async({ref,phase})=>{
  calls.push(ref);return phase==='metadata'?{episodes:[{season:1,number:4,ref:ep(1)},{season:2,number:4,ref:ep(2)}]}:{servers:[media]};}});
 const result=await runtime.resolve(input);assert.equal(result.status,'success');assert.equal(calls[1],ep(2));
});
test('missing exact episode cannot fall back to the first one',async()=>{
 let calls=0;const runtime=createPinnedPlayback({loadDetails:async()=>{calls++;return{episodes:[{season:1,number:4,ref:ep(1)}]};}});
 const result=await runtime.resolve(input);assert.equal(result.playback_reason,'PINNED_EPISODE_NOT_FOUND');assert.equal(calls,1);
});
test('cross-provider reference from metadata is rejected',async()=>{
 const runtime=createPinnedPlayback({loadDetails:async()=>({episodes:[{season:2,number:4,ref:'akwam:'+Buffer.from('https://ak.sv/episode/4').toString('base64url')}]})});
 await assert.rejects(runtime.resolve(input),/PINNED_SOURCE_CONFLICT/);
});
test('web rejects protected native-only links instead of promising playback',async()=>{
 let probed=false;
 const runtime=createPinnedPlayback({probe:async()=>{probed=true;return{playable:true,container:'mp4',statusCode:200,webPlayable:false}},loadDetails:async()=>({servers:[{...media,web_playable:false,headers:{Referer:'https://wecima.show/'}}]})});
 const result=await runtime.resolve({...input,type:'movie'});assert.equal(result.playback_reason,'PINNED_DIRECT_WEB_UNAVAILABLE');
 assert.equal(probed,true);
});
test('trusted browser-verified sources do not inherit forbidden native headers',async()=>{
 const runtime=createPinnedPlayback({loadDetails:async()=>({servers:[{...media,headers:{Referer:'https://wecima.show/'}}]})});
 const result=await runtime.resolve({...input,type:'movie'});assert.deepEqual(result.servers[0].headers,{});
});

test('a pinned source with native header hints can recover through browser bytes despite generic MIME',async()=>{
 const runtime=createPinnedPlayback({browserOrigin:'https://example.org',loadDetails:async()=>({servers:[{...media,web_playable:false,headers:{Referer:'https://wecima.show/',Cookie:'private-session'}}]}),probe:(candidate,options)=>probeHarvestMedia(candidate,{...options,headProbe:async()=>({statusCode:200,playable:false,webPlayable:false}),fetchImpl:async(_url,request)=>{
  assert.equal(request.headers.Origin,'https://example.org');assert.equal(request.headers.Referer,'https://example.org/');assert.equal(request.headers.Cookie,undefined);
  return{status:206,headers:new Headers({'content-type':'application/octet-stream','access-control-allow-origin':'https://example.org'}),bytes:Buffer.from('000000186674797069736f6d00000001','hex')};
 }})});
 const result=await runtime.resolve({...input,type:'movie'});assert.equal(result.status,'success');assert.deepEqual(result.servers[0].headers,{});assert.equal(result.servers[0].web_playable,true);
});
