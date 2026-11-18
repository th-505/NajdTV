import test from 'node:test';
import assert from 'node:assert/strict';
import {BROWSE_SECTIONS,browseRequest,browseCatalog} from '../server/catalog-browser.mjs';
import {CinemaCategories} from '../web/core/catalog-config.js';
test('web filters exactly match canonical sections and selection constrains TMDB request',()=>{
 for(const [section,rows]of Object.entries(BROWSE_SECTIONS))assert.deepEqual(CinemaCategories[section].map(x=>[x.url,x.title]),rows);
 assert.equal(browseRequest('catalog:movie:ar').params.with_original_language,'ar');
 assert.equal(browseRequest('catalog:anime:tv').params.with_genres,'16');
 assert.equal(browseRequest('catalog:turkish:movie').path,'/discover/movie');
 assert.throws(()=>browseRequest('https://evil/'),/INVALID_CATALOG_SECTION/);
});
test('canonical refs and truthful missing values reach every platform',async()=>{
 const result=await browseCatalog({catalog:async()=>({results:[{id:1,name:'Show',first_air_date:'2026-01-01',vote_count:0}],page:1,total_pages:2})},'catalog:tv:all',1);
 assert.equal(result.data[0].id,'tmdb:tv:1');assert.equal(result.data[0].rating,null);assert.equal(result.has_more,true);
});

test('foreign means non-Arabic, not just English; Japanese anime stays out of ordinary series',async()=>{
 assert.equal(browseRequest('catalog:tv:en').params.with_original_language,undefined);
 const rows=[
  {id:1,name:'عربي',original_language:'ar'},
  {id:2,name:'French drama',original_language:'fr'},
  {id:3,name:'Japanese anime',original_language:'ja',genre_ids:[16]},
  {id:4,name:'American cartoon',original_language:'en',genre_ids:[16]},
  {id:5,name:'Turkish drama',original_language:'tr',genre_ids:[18]},
  {id:6,name:'Excluded explicit',original_language:'en',adult:true},
 ];
 const result=await browseCatalog({catalog:async()=>({results:rows})},'catalog:tv:en',1);
 assert.deepEqual(result.data.map(row=>row.tmdbId),['2','4','5']);
 assert(result.data.find(row=>row.tmdbId==='5').genres.includes('تركي'));
 const anime=await browseCatalog({catalog:async()=>({results:[rows[2]]})},'catalog:anime:tv',1);
 assert.deepEqual(anime.data[0].genres,['أنمي']);
 assert.equal(anime.data[0].type,'series','classification never changes canonical movie/TV identity');
});
