import test from 'node:test';
import assert from 'node:assert/strict';
import {PROVIDERS_MAP} from '../server/browser/registry.mjs';
import {externalProviderDirectory,providerGroups,searchProviderGroup} from '../server/browser/provider-directory.mjs';

test('the directory categorizes both integrated and external providers without inventing playback capability',()=>{
  const directory=externalProviderDirectory();
  assert.equal(directory.length,16);
  assert.equal(new Set(directory.map(item=>item.id)).size,16);
  assert.ok(directory.every(item=>item.access==='external' && new URL(item.url).protocol==='https:' && item.groups.length));
  for (const [id,{meta}] of PROVIDERS_MAP) {
    if (meta.capabilities?.live && !meta.capabilities?.episodes) continue;
    assert.ok(providerGroups(id).length,id);
  }
  assert.ok(providerGroups('shoof-live').includes('turkish'));
  assert.ok(providerGroups('shoof-live').includes('indian'));
});

const provider = id => ({id, capabilities:{search:true}});
test('specialized search stays in its group and tries the selected provider first', async()=>{
  const seen=[];
  const result=await searchProviderGroup({group:'turkish',query:'اختبار',preferred:'3isk',
    providers:['fosta','animezid','3isk'].map(provider),
    search:async id=>{seen.push(id); if(id==='3isk') throw Error('offline'); return [{ref:'fosta:result'}];},
    globalSearch:async()=>assert.fail('unneeded fallback')});
  assert.deepEqual(seen,['3isk','fosta']);
  assert.deepEqual(result,{items:[{ref:'fosta:result'}],scope:'beta',fallback:false});
});

test('general search runs once after specialized errors or empty results', async()=>{
  const seen=[];
  const result=await searchProviderGroup({group:'anime',query:'كونان',
    providers:['animezid','anime4up','3isk'].map(provider),
    search:async id=>{seen.push(id); if(id==='animezid') throw Error('offline');return [];},
    globalSearch:async q=>{seen.push(q);return {data:[{ref:'tmdb:tv:1'}]};}});
  assert.deepEqual(seen,['animezid','anime4up','كونان']);
  assert.deepEqual(result,{items:[{ref:'tmdb:tv:1'}],scope:'najd',fallback:true});
});
