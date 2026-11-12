import test from'node:test';import assert from'node:assert/strict';
import{probeHarvestMedia}from'../server/harvest/media-probe.mjs';
import{fetchSafeResponse}from'../server/scrapers/shared/http.mjs';
const candidate={url:'https://cdn.example/video.mp4',headers:{Referer:'https://source.example/'}};
const headProbe=async()=>({playable:true,container:'mp4',webPlayable:false,statusCode:200});
test('successful HEAD cannot certify HTML, empty or broken container bytes',async()=>{
 for(const bytes of [Buffer.from('<html>blocked</html>'),Buffer.alloc(0),Buffer.from('not a video')])assert.equal((await probeHarvestMedia(candidate,{headProbe,fetchImpl:async()=>({status:206,bytes})})).playable,false);
 const bytes=Buffer.from('000000186674797069736f6d00000001','hex');
 const result=await probeHarvestMedia(candidate,{headProbe,fetchImpl:async(_url,options)=>{assert.equal(options.headers.Referer,candidate.headers.Referer);assert.equal(options.headers.Range,'bytes=0-32767');return{status:206,bytes}}});
 assert.equal(result.container_verified,true);assert.equal(result.webPlayable,false);
});
test('binary prefix cancels an ignored Range without corrupting bytes or reading a large response',async()=>{
 let cancelled=false,reads=0;
 const body=new ReadableStream({pull(c){reads++;c.enqueue(new Uint8Array(8192).fill(255));},cancel(){cancelled=true}});
 const r=await fetchSafeResponse(candidate.url,{allowHttp:false,responseType:'bytes',prefixBytes:10000,maxRetries:0,fetchImpl:async()=>new Response(body,{headers:{'content-type':'video/mp4','content-length':'2000000000'}})});
 assert.equal(r.bytes.length,10000);assert.equal(r.bytes[0],255);assert.equal(r.html,'');assert.equal(cancelled,true);assert(reads<=4);
});
test('binary mode still blocks unsafe redirect targets before fetching them',async()=>{
 let calls=0;await assert.rejects(()=>fetchSafeResponse(candidate.url,{allowHttp:false,responseType:'bytes',prefixBytes:10000,maxRetries:0,fetchImpl:async()=>{calls++;return new Response(null,{status:302,headers:{location:'https://127.0.0.1/private'}})}}));assert.equal(calls,1);
});
test('a real MP4 container is accepted when a CDN omits both MIME headers',async()=>{
 const result=await probeHarvestMedia(candidate,{headProbe:async()=>({playable:false,container:null,statusCode:200,webPlayable:false}),fetchImpl:async()=>({status:200,bytes:Buffer.from('000000186674797069736f6d00000001','hex')})});
 assert.equal(result.playable,true);assert.equal(result.container,'mp4');assert.equal(result.container_verified,true);assert.equal(result.webPlayable,false);
});

test('browser-context bytes certify an octet-stream MP4 without CORS or source-only headers',async()=>{
 const result=await probeHarvestMedia({...candidate,headers:{Referer:'https://source.example/',Cookie:'private-session','User-Agent':'source-agent'}},{platform:'web',
  headProbe:async(_candidate,options)=>{assert.equal(options.platform,'web');return{playable:false,container:null,statusCode:200,webPlayable:false}},
  fetchImpl:async(_url,options)=>{
   assert.deepEqual(options.headers,{Referer:'https://th-505.github.io/',Range:'bytes=0-32767'});
   return{status:206,headers:new Headers({'content-type':'application/octet-stream'}),bytes:Buffer.from('000000186674797069736f6d00000001','hex')};
  }});
 assert.equal(result.container,'mp4');assert.equal(result.playable,true);assert.equal(result.webPlayable,true);
});

test('generic MIME never makes HTML or a native-only format web playable',async()=>{
 for(const [bytes,cors]of [[Buffer.from('<html>access denied</html>'),'*'],[Buffer.from('RIFF0000AVI '),'*']]){
  const result=await probeHarvestMedia(candidate,{platform:'web',headProbe:async()=>({statusCode:200,webPlayable:true}),fetchImpl:async()=>({status:206,headers:new Headers(cors?{'access-control-allow-origin':cors}:{}),bytes})});
  assert.equal(result.webPlayable,false);
 }
});

test('HLS still requires frontend CORS and explicit cross-origin resource restrictions stay enforced',async()=>{
 const bytes=Buffer.from('#EXTM3U\n#EXT-X-TARGETDURATION:10\n');
 const hls=await probeHarvestMedia({url:'https://cdn.example/index.m3u8'},{platform:'web',headProbe:async()=>({statusCode:200}),fetchImpl:async(_url,options)=>{
  assert.equal(options.headers.Origin,'https://th-505.github.io');return{status:200,headers:new Headers(),bytes};
 }});assert.equal(hls.playable,true);assert.equal(hls.webPlayable,false);
 const blocked=await probeHarvestMedia(candidate,{platform:'web',headProbe:async()=>({statusCode:200}),fetchImpl:async()=>({status:206,headers:new Headers({'cross-origin-resource-policy':'same-origin'}),bytes:Buffer.from('000000186674797069736f6d00000001','hex')})});
 assert.equal(blocked.webPlayable,false);
});

test('guarded plain-video requests omit generated Origin on every redirect while HLS keeps its frontend Origin',async()=>{
 let calls=0;
 await fetchSafeResponse(candidate.url,{method:'HEAD',allowHttp:false,omitOrigin:true,maxRetries:0,headers:{Referer:'https://th-505.github.io/'},fetchImpl:async(_url,options)=>{
  calls++;assert.equal(Object.keys(options.headers).some(k=>k.toLowerCase()==='origin'),false);assert.equal(options.headers.Referer,'https://th-505.github.io/');
  return calls===1?new Response(null,{status:302,headers:{location:'https://alternate.example/video.mp4'}}):new Response(null,{status:200,headers:{'content-type':'video/mp4'}});
 }});assert.equal(calls,2);
 await fetchSafeResponse('https://cdn.example/index.m3u8',{method:'HEAD',allowHttp:false,maxRetries:0,headers:{Origin:'https://th-505.github.io'},fetchImpl:async(_url,options)=>{
  assert.equal(options.headers.Origin,'https://th-505.github.io');return new Response(null,{status:200});
 }});
});
