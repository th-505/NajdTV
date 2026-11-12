import test from 'node:test';import assert from 'node:assert/strict';
import {guardedProviderFetch} from '../server/scrapers/shared/http.mjs';
import {createAlooyProvider} from '../server/providers/alooy.mjs';
import {createLarozaProvider} from '../server/providers/laroza.mjs';
test('legacy facade rejects private DNS before requesting and validates redirect targets',async()=>{
  let calls=0;
  await assert.rejects(guardedProviderFetch('https://source.example/',{}, {fetchImpl:async()=>{calls++;return new Response('bad')},dnsLookupImpl:async()=>[{address:'127.0.0.1',family:4}]}),/PRIVATE|UNSAFE|SSRF/);
  assert.equal(calls,0);
  await assert.rejects(guardedProviderFetch('https://source.example/',{}, {fetchImpl:async()=>new Response(null,{status:302,headers:{location:'http://127.0.0.1/'}})}),/PROTOCOL|UNSAFE|SSRF/);
});
test('legacy facade enforces body size and deadline',async()=>{
  await assert.rejects(guardedProviderFetch('https://source.example/',{}, {maxBytes:8,fetchImpl:async()=>new Response('a'.repeat(40))}),/BODY_TOO_LARGE/);
  await assert.rejects(guardedProviderFetch('https://source.example/',{}, {timeoutMs:5,fetchImpl:async(_u,o)=>new Promise((_r,reject)=>o.signal.addEventListener('abort',()=>reject(new DOMException('timeout','TimeoutError'))))}),/timeout/i);
});
test('Alooy and Laroza validate JSON structure despite HTML Content-Type',async()=>{
  const alooy=createAlooyProvider({fetchImpl:async()=>new Response(JSON.stringify([{title:'شباب',url:'https://fa.alooytv16.xyz/watch/abc.html',image:'/poster.jpg'}]),{headers:{'content-type':'text/html'}})});
  assert.equal((await alooy.search('شباب')).data.length,1);
  const ref='laroza:'+Buffer.from('/play.php?vid=abc').toString('base64url');
  const laroza=createLarozaProvider({enabled:true,edgeBase:'https://edge.example',fetchImpl:async()=>new Response(JSON.stringify({status:'success',source:'laroza',data:[{ref,title:'مثال'}]}),{headers:{'content-type':'text/html'}})});
  assert.equal((await laroza.category()).data[0].ref,ref);
  const invalid=createLarozaProvider({enabled:true,edgeBase:'https://edge.example',fetchImpl:async()=>new Response('<html>broken</html>',{headers:{'content-type':'application/json'}})});
  await assert.rejects(invalid.category(),/BAD_EDGE_RESPONSE/);
});

test('a stalled DNS lookup has a deadline and never starts an HTTP request',async()=>{
  let calls=0;
  await assert.rejects(guardedProviderFetch('https://dns.example/',{}, {timeoutMs:5,dnsLookupImpl:async()=>new Promise(()=>{}),fetchImpl:async()=>{calls++;return new Response('not reached')}}),e=>e.code==='NETWORK_TIMEOUT'&&/DNS_TIMEOUT/.test(e.message));
  assert.equal(calls,0);
});

test('legacy HTTP errors retain safe codes without echoing source query values',async()=>{
  const p=createAlooyProvider({fetchImpl:async()=>new Response('upstream failed',{status:500})});
  await assert.rejects(p.search('private-query'),e=>e.message==='ALOOY_HTTP_500'&&e.error_code==='UPSTREAM_UNAVAILABLE'&&!e.message.includes('private-query'));
});
