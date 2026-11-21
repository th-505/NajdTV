import test from 'node:test';import assert from 'node:assert/strict';import http from 'node:http';
import {createMitvRuntimeServer} from '../server/index-runtime.mjs';import {createLiveCatalog} from '../server/live-catalog.mjs';
test('live catalog uses the existing HTTP boundary and never accepts client-supplied fetch targets',async()=>{
 let fetches=0;
 const liveCatalog=createLiveCatalog({fetchPlaylist:async()=>{fetches++;return '#EXTM3U\n#EXTINF:-1 tvg-id="AlEkhbariya.sa",One\nhttps://cdn.example.com/live.m3u8';}});
 const baseServer=http.createServer((req,res)=>{res.writeHead(418);res.end();});
 const server=createMitvRuntimeServer({baseServer,liveCatalog});await new Promise(r=>server.listen(0,'127.0.0.1',r));
 const base='http://127.0.0.1:'+server.address().port;
 try{
  assert.equal((await (await fetch(base+'/api/v1/live/groups')).json()).data.length,11);assert.equal(fetches,0);
  assert.equal((await fetch(base+'/api/v1/live/groups',{method:'POST'})).status,405);
  assert.equal((await fetch(base+'/api/v1/live/catalog?group=http://127.0.0.1')).status,400);assert.equal(fetches,0);
  assert.equal((await fetch(base+'/api/v1/live/catalog',{headers:{Origin:'https://evil.example'}})).status,403);
  const list=await (await fetch(base+'/api/v1/live/catalog?group=sa')).json();assert.equal(fetches,1);
  const path=base+'/api/v1/live/playback?ref='+encodeURIComponent(list.data[0].ref);
  const a=await (await fetch(path)).json(),b=await (await fetch(path)).json();
  assert.notEqual(a.data.playback_session,b.data.playback_session);assert.equal(a.data.playback_mode,'direct');
  assert.equal((await fetch(base+'/api/v1/live/playback?ref=https://127.0.0.1')).status,400);
  assert.equal((await fetch(base+'/unchanged')).status,418);
 }finally{server.closeAllConnections();await new Promise(r=>server.close(r));}
});
