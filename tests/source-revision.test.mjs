import test from 'node:test';import assert from 'node:assert/strict';
import {readSourceRevision} from '../server/source-revision.mjs';
import {createServer} from '../server/app.mjs';
test('health revision accepts only a full build SHA and never executes supplied text',()=>{
  const sha='a'.repeat(40);let calls=0;
  assert.equal(readSourceRevision({env:{RENDER_GIT_COMMIT:sha},git:()=>{calls++;}}).source_commit,sha);
  assert.equal(readSourceRevision({env:{RENDER_GIT_COMMIT:'invalid; injected'},git:()=>{calls++;}}).source_commit,null);
  assert.equal(calls,0);
  assert.equal(readSourceRevision({env:{},git:(...args)=>args[0]==='rev-parse'?sha:' M file'}).source_tree_dirty,true);
  assert.equal(readSourceRevision({env:{},git:()=>{throw Error('git unavailable')}}).source_commit,null);
});
test('health exposes revision and safe harvest booleans without credential material',async()=>{
  const server=createServer();await new Promise(r=>server.listen(0,'127.0.0.1',r));
  try{
    const response=await fetch(`http://127.0.0.1:${server.address().port}/health`),body=await response.json();
    assert.equal(response.status,200);assert.equal(body.version,'4.0.2');
    assert(body.source_commit===null || /^[a-f0-9]{40}$/.test(body.source_commit));
    assert.equal(typeof body.harvest_enabled,'boolean');assert.equal(typeof body.harvest_configured,'boolean');
    assert(!/apikey|service_role|authorization/i.test(JSON.stringify(body)));
  }finally{server.closeAllConnections();await new Promise(r=>server.close(r))}
});
