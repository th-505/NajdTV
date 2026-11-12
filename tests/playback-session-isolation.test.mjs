import test from 'node:test';
import assert from 'node:assert/strict';
import {createSessionPlayback} from '../server/harvest/session-playback.mjs';
import {create3iskRuntime} from '../server/3isk-runtime.mjs';
import {encode3iskRef} from '../server/providers/3isk.mjs';
import {createAlooyProvider,encodeAlooyRef,ALOOY_ORIGIN} from '../server/providers/alooy.mjs';
import {createServer} from '../server/app.mjs';
import {createPlaybackSessions} from '../server/playback-sessions.mjs';

test('two overlapping extractions get separate signed URLs/sessions and never mutate the shared cache',async()=>{
 const now=Date.now();let calls=0,active=0,maximum=0,writes=0;
 const entries=[{meta:{id:'fixture',capabilities:{search:true,details:true},domains:['https://source.example']},module:{
  scrapeDetails:async()=>{const token=++calls;maximum=Math.max(maximum,++active);await new Promise(r=>setTimeout(r,10));active--;
   return {title:'Film 2026',servers:[{kind:'direct',url:`https://cdn.example/film.mp4?token=${token}&expires=${Math.floor(now/1000)+300}`}]}},
 }}];
 const resolve=createSessionPlayback({store:{setEpisode(){writes++}},entries,now:()=>now,
  probe:async()=>({playable:true,container:'mp4',container_verified:true,statusCode:206})});
 const input={work:{ref:'source:fixture:0123456789abcdef01234567',metadata:{title:'Film',year:2026,identity_scope:'source'}},
  row:{provider:'fixture',source_ref:'https://source.example/film'},season:0,episode:0};
 const [a,b]=await Promise.all([resolve(input),resolve(input)]);
 assert.equal(maximum,2);assert.equal(calls,2);assert.equal(writes,0);
 assert.equal(a.length,1);assert.equal(b.length,1);
 assert.notEqual(a[0].url,b[0].url);assert.notEqual(a[0].playback_session,b[0].playback_session);
 assert.equal(a[0].playback_scope,'request');
 assert(Date.parse(a[0].expires_at)<=now+300000);
});

test('HTTP fresh 3isk resolution bypasses durable/local/pending cache and rejects expired tokens',async()=>{
 const now=Date.now(),ref=encode3iskRef('https://3iskk.xyz/watch/episodes/test/');let calls=0,cacheReads=0;
 const provider={resolve:async()=>{const token=++calls;await new Promise(r=>setTimeout(r,5));const expiry=Math.floor(now/1000)+3600;
  return {playback_mode:'direct',media_url:`https://s1.ukrcdn.xyz/hls/test/master.m3u8?token=${token}&expires=${expiry}`,
   expires_at:new Date(expiry*1000).toISOString(),playback_headers:{Referer:'https://s1.ukrcdn.xyz/','User-Agent':'fixture'}};}};
 const runtime=create3iskRuntime({provider,now:()=>now,store:{get(){cacheReads++;throw Error('must not read shared tokens')}}});
 const [a,b]=await Promise.all([runtime.resolve(ref,{fresh:true}),runtime.resolve(ref,{fresh:true})]);
 assert.equal(cacheReads,0);assert.equal(calls,2);assert.notEqual(a.media_url,b.media_url);assert.notEqual(a.playback_session,b.playback_session);
 const expired=create3iskRuntime({now:()=>now,store:null,provider:{resolve:async()=>({...a,expires_at:new Date(now-1).toISOString()})}});
 await assert.rejects(expired.resolve(ref,{fresh:true}),/INVALID_CACHE_PAYLOAD/);
});

test('Alooy forced playback requests do not join another viewer pending HTML/token',async()=>{
 let calls=0;const provider=createAlooyProvider({fetchImpl:async()=>{const token=++calls;
  await new Promise(r=>setTimeout(r,5));return new Response(`<h1>Film</h1><video><source src="https://vid8.ujeklsj.site/test.mp4?token=${token}"></video>`);}});
 const ref=encodeAlooyRef(ALOOY_ORIGIN+'/watch/test.html?key=abc');
 const [a,b]=await Promise.all([provider.details(ref,{refresh:true}),provider.details(ref,{refresh:true})]);
 assert.equal(calls,2);assert.notEqual(a.media_path,b.media_path);
});

test('two HTTP viewers get fresh credentials on the legacy details route',async()=>{
 let calls=0;const expiry=Math.floor(Date.now()/1000)+3600;
 const runtime=create3iskRuntime({store:null,provider:{resolve:async()=>{
  const token=++calls;await new Promise(r=>setTimeout(r,5));
  return {playback_mode:'direct',media_url:`https://s1.ukrcdn.xyz/hls/test/master.m3u8?token=${token}&expires=${expiry}`,
   expires_at:new Date(expiry*1000).toISOString(),playback_headers:{Referer:'https://s1.ukrcdn.xyz/','User-Agent':'fixture'}};
 }}});
 const ref=encode3iskRef('https://3iskk.xyz/watch/episodes/test/');
 // Seed the old process-wide cache first. HTTP delivery must never reuse it.
 await runtime.resolve(ref);
 const server=createServer({iskRuntime:runtime});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 try{
  const url=`http://127.0.0.1:${server.address().port}/api/cinema/details?ref=${encodeURIComponent(ref)}`;
  const responses=await Promise.all([fetch(url),fetch(url)]);
  for(const response of responses){assert.equal(response.status,200);assert.equal(response.headers.get('cache-control'),'no-store');}
  const [a,b]=await Promise.all(responses.map(r=>r.json()));
  assert.equal(calls,3);assert.notEqual(a.media_url,b.media_url);
 }finally{await new Promise(r=>server.close(r));}
});

test('polls reuse only their own session; renewing A never revokes or replaces B',async()=>{
 let now=Date.now(),calls=0;
 const sessions=createPlaybackSessions({now:()=>now});
 const a='a'.repeat(32),b='b'.repeat(32),identity=['same-work',1,1];
 const extract=async()=>[{url:`https://cdn.example/video.mp4?token=${++calls}`,expires_at:new Date(now+120000).toISOString()}];
 assert.equal(sessions(a,identity,extract).state,'running');
 assert.equal(sessions(a,identity,extract).state,'running');
 assert.equal(sessions(b,identity,extract).state,'running');
 await new Promise(r=>setImmediate(r));
 const firstA=sessions(a,identity,extract),firstB=sessions(b,identity,extract);
 assert.equal(calls,2);assert.equal(firstA.state,'ready');assert.equal(firstB.state,'ready');
 assert.notEqual(firstA.servers[0].url,firstB.servers[0].url);
 const newA='c'.repeat(32);sessions(newA,identity,extract);await new Promise(r=>setImmediate(r));
 assert.equal(sessions(b,identity,extract).servers[0].url,firstB.servers[0].url);
 assert.notEqual(sessions(newA,identity,extract).servers[0].url,firstA.servers[0].url);
 now+=90001;
 assert.equal(sessions(a,identity,extract).state,'running','expired capabilities must extract again');
 assert.throws(()=>sessions('forged',identity,extract),/INVALID_PLAYBACK_SESSION/);
});
