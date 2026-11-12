import test from 'node:test';import assert from 'node:assert/strict';
import {sourceResponse,sourceItem,providerErrorCode,providerContract,parsedCollection} from '../shared/provider-contract.js';
test('canonical source fields preserve editions and never promote legacy default seasons',()=>{
  const r=sourceResponse({source:'fixture',episodes:[{ref:'fixture:x',number:1217,season:1}],partial:true,next_offset:200});
  assert.equal(r.episodes[0].episode_number,1217);assert.equal(r.episodes[0].season_number,null);
  assert.equal(r.episodes[0].episode_id,'fixture:x');assert.equal(r.state,'partial');assert.equal(r.next_cursor,'200');
  assert.equal(sourceItem({edition:'dubbed'},'fixture').edition,'dubbed');
});
test('errors, successful empty results and asynchronous states stay distinct',async()=>{
  for(const [code,canonical] of [['NETWORK_TIMEOUT','TIMEOUT'],['ACCESS_BLOCKED','ACCESS_BLOCKED'],['BAD_EDGE_RESPONSE','STRUCTURE_CHANGED']]) assert.equal(providerErrorCode(code),canonical);
  assert.equal(sourceResponse({source:'x',data:[]}).state,'empty');
  for(const state of ['queued','running','partial','unavailable']) assert.equal(sourceResponse({state,data:[]}).state,state);
  const p=providerContract({search:async()=>{throw Object.assign(Error('NETWORK_TIMEOUT'),{code:'NETWORK_TIMEOUT'})}},'x');
  await assert.rejects(p.search(),e=>e.error_code==='TIMEOUT'&&e.state==='unavailable');
});

test('unrecognized markup and JSON syntax failures are not successful empty results',()=>{
  assert.throws(()=>parsedCollection([], '<html>different site</html>'),/STRUCTURE_CHANGED/);
  assert.deepEqual(parsedCollection([], '<div class="no-results">لا توجد نتائج</div>'),[]);
  assert.equal(providerErrorCode(new SyntaxError('Unexpected token')), 'STRUCTURE_CHANGED');
  assert.equal(sourceResponse({data:{state:'queued'}}).state,'queued');
});
