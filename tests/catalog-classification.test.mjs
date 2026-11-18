import test from 'node:test';
import assert from 'node:assert/strict';
import {createTmdbRuntime,__tmdbTest} from '../server/tmdb-runtime.mjs';
import {catalogLabels} from '../server/catalog-classification.mjs';
test('upstream adult flags are excluded even when an upstream ignores include_adult=false',async()=>{
 assert.equal(__tmdbTest.normalizeResult({id:1,title:'Excluded',media_type:'movie',adult:true}),null);
 assert.throws(()=>__tmdbTest.normalizeDetails({title:'Excluded',adult:true},'movie',1),/TMDB_ADULT_CONTENT_EXCLUDED/);
 const runtime=createTmdbRuntime({apiKey:'fixture',fetchImpl:async()=>new Response(JSON.stringify({results:[{id:1,adult:true},{id:2,adult:false},{id:3}]}))});
 const body=await runtime.catalog('/discover/movie');
 assert.deepEqual(body.results.map(row=>row.id),[2,3]);
});
test('Western animation and missing metadata never fabricate an anime label',()=>{
 assert.deepEqual(catalogLabels({original_language:'en',genre_ids:[16]}),[]);
 assert.deepEqual(catalogLabels({original_language:'ja',genre_ids:[18]}),[]);
 assert.deepEqual(catalogLabels({original_language:'ja',genres:[{id:16,name:'Animation'}]}),['أنمي']);
 assert.deepEqual(catalogLabels({original_language:'tr'}),['تركي']);
 assert.deepEqual(catalogLabels({genre_ids:[16]}),[]);
});
