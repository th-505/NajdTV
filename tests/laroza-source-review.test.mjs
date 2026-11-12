import test from 'node:test';import assert from 'node:assert/strict';
import worker from '../edge/src/laroza.mjs';
import {createLarozaProvider} from '../server/providers/laroza.mjs';
test('Laroza rejects an unreviewed source redirect and retains the actionable cause',async()=>{
  const original=globalThis.fetch;let calls=0;
  globalThis.fetch=async()=>{calls++;return new Response(null,{status:301,headers:{location:'https://unreviewed.example/moslslat4.php'}})};
  try{
    const response=await worker.fetch(new Request('https://internal/category?section=series&page=1'),{});
    const body=await response.json();assert.equal(response.status,503);
    assert.equal(body.error,'LAROZA_CATALOG_UNAVAILABLE');
    assert.equal(body.upstream_reason,'LAROZA_SOURCE_REDIRECT_REQUIRES_REVIEW');
    assert.equal(body.error_code,'ACCESS_BLOCKED');assert.equal(body.state,'unavailable');assert.equal(calls,1);
  }finally{globalThis.fetch=original}
});
test('Node facade propagates typed gateway failure instead of successful empty data',async()=>{
  const p=createLarozaProvider({edgeBase:'https://edge.example',fetchImpl:async()=>Response.json({error:'LAROZA_CATALOG_UNAVAILABLE',error_code:'ACCESS_BLOCKED',upstream_reason:'LAROZA_SOURCE_REDIRECT_REQUIRES_REVIEW'},{status:503})});
  await assert.rejects(p.category(),e=>e.error_code==='ACCESS_BLOCKED'&&e.upstream_reason==='LAROZA_SOURCE_REDIRECT_REQUIRES_REVIEW'&&e.state==='unavailable');
});
