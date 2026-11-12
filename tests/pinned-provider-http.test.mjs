import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from '../server/app.mjs';
import {getProvider} from '../server/scrapers/registry.mjs';

async function run(options, action) {
 const server=createServer({catalogStore:null,harvestService:{start(){},async stop(){}},browserConfigurationService:{async refresh(){},close(){}},...options});
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 try{await action('http://127.0.0.1:'+server.address().port)}
 finally{server.closeAllConnections();await new Promise(resolve=>server.close(resolve))}
}

test('registered Akwam, MyCima and Fosta resolvers run for the exact episode without a resolveOnDetails marker',async()=>{
 for(const provider of ['akwam','mycima','fosta']){
  const origin=getProvider(provider).meta.domains[0];
  const ref=path=>provider+':'+Buffer.from(new URL(path,origin).href).toString('base64url');
  const series=ref('/series/observed'),episode=ref('/episode/2'),calls=[];
  const entry={meta:{capabilities:{resolve:true}},module:{
   scrapeDetails:async selected=>{calls.push(['details',selected]);return selected===series?{type:'series',episodes:[{season:3,number:2,ref:episode}]}:{type:'series',season_number:3,episode_number:2,servers:[]}},
   resolveStream:async selected=>{calls.push(['resolve',selected]);const stream={url:'https://cdn.example/2.mp4',kind:'direct',web_playable:true};return provider==='akwam'?{...stream,type:'mp4',streamType:'mp4'}:{servers:[stream]}}
  }};
  await run({pinnedProviderLookup:()=>entry},async base=>{
   const response=await fetch(base+'/api/v1/playback?'+new URLSearchParams({ref:series,type:'series',season:'3',episode:'2',platform:'web'}));
   const result=await response.json();assert.equal(result.status,'success',JSON.stringify(result));assert.equal(result.servers.length,1);
   assert.deepEqual(calls,[['details',series],['details',episode],['resolve',episode]]);
  });
 }
});

test('primary url and streamUrl resolver contracts are normalized into validated source candidates',async()=>{
 const ref='akwam:'+Buffer.from('https://akwam.ss/movie/42/observed').toString('base64url');
 for(const field of ['url','streamUrl']){
  await run({pinnedProviderLookup:()=>({meta:{capabilities:{resolve:true}},module:{scrapeDetails:async()=>({type:'movie',servers:[]}),resolveStream:async()=>({[field]:'https://cdn.example/movie.mp4',type:'mp4',web_playable:true})}})},async base=>{
   const result=await(await fetch(base+'/api/v1/playback?'+new URLSearchParams({ref,type:'movie',platform:'web'}))).json();
   assert.equal(result.status,'success');assert.equal(result.servers[0].url,'https://cdn.example/movie.mp4');
  });
 }
});

test('a selected source movie invokes its resolver while disabled resolve capability remains respected',async()=>{
 const ref='akwam:'+Buffer.from('https://akwam.ss/movie/42/observed').toString('base64url');
 for(const enabled of [true,false]){
  let calls=0;
  await run({pinnedProviderLookup:()=>({meta:{capabilities:{resolve:enabled}},module:{scrapeDetails:async()=>({type:'movie',servers:[]}),resolveStream:async()=>{calls++;return{servers:[{url:'https://cdn.example/movie.mp4',kind:'direct',web_playable:true}]}}}})},async base=>{
   const result=await(await fetch(base+'/api/v1/playback?'+new URLSearchParams({ref,type:'movie',platform:'web'}))).json();
   assert.equal(calls,enabled?1:0);assert.equal(result.status,enabled?'success':'unavailable');
  });
 }
});

test('dedicated source runtimes resolve movies rather than returning metadata-only and retain the requested platform',async()=>{
 const origin=getProvider('3isk').meta.domains[0],ref='3isk:'+Buffer.from(new URL('/movie/42',origin).href).toString('base64url');
 const calls=[];
 await run({runtimeService:{},iskRuntime:{metadata:async()=>{throw Error('MOVIE_METADATA_ONLY_MUST_NOT_RUN')},details:async(selected,options)=>{calls.push({selected,platform:options.platform});return{servers:options.platform==='native'?[]:[{url:'https://cdn.example/movie.mp4',kind:'direct',web_playable:true}]}}}},async base=>{
  const result=await(await fetch(base+'/api/v1/playback?'+new URLSearchParams({ref,type:'movie',platform:'web'}))).json();
  assert.equal(result.status,'success');
  const native=await(await fetch(base+'/api/v1/playback?'+new URLSearchParams({ref,type:'movie',platform:'native'}))).json();
  assert.equal(native.status,'unavailable');assert.deepEqual(calls,[{selected:ref,platform:'web'},{selected:ref,platform:'native'}]);
 });
});
