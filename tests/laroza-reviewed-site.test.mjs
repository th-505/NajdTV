import test from 'node:test';import assert from 'node:assert/strict';
import{readFileSync}from'node:fs';
import{LAROZA_CONFIG,createLarozaEdge,larozaRef,parseLarozaCatalog,parseLarozaDetails}from'../edge/src/laroza.mjs';
import{createLarozaProvider}from'../server/providers/laroza.mjs';
import{PROVIDER_META as najd,LAROZA_SITE_CONFIG as primary}from'../server/scrapers/sites/laroza.mjs';
import{PROVIDER_META as beta,LAROZA_SITE_CONFIG as secondary}from'../server/browser/providers/sites/laroza.mjs';
const fixture=name=>readFileSync(new URL('../scripts/fixtures/laroza/'+name,import.meta.url),'utf8');
test('reviewed Laroza origin has matching catalog and eight observed episodes, without invented seasons',()=>{
 assert.equal(LAROZA_CONFIG.origin,'https://laroza1.site');
 assert.equal(primary.baseUrl,LAROZA_CONFIG.origin);assert.equal(secondary.baseUrl,LAROZA_CONFIG.origin);
 assert(najd.domains.includes(LAROZA_CONFIG.origin));assert(beta.domains.includes(LAROZA_CONFIG.origin));
 const rows=parseLarozaCatalog(fixture('reviewed-site-catalog.html'));
 assert.equal(rows.length,2);assert.match(rows[0].title,/Did Someone Happen to Mention Me/);
 assert(parseLarozaCatalog(fixture('reviewed-site-search.html')).some(r=>r.title.includes('Did Someone')));
 const details=parseLarozaDetails(fixture('reviewed-site-details.html'),rows[0].ref);
 assert.equal(details.episodes.length,8);assert.deepEqual(details.episodes.map(r=>r.episode_number),[1,2,3,4,5,6,7,8]);
 assert(details.episodes.every(r=>r.season_number===null));
});
test('reviewed origin is enabled while cross-origin redirects remain blocked',async()=>{
 let calls=0;const facade=createLarozaProvider({edgeBase:'https://edge.example',fetchImpl:async()=>{
  calls++;return Response.json({status:'success',source:'laroza',data:parseLarozaCatalog(fixture('reviewed-site-catalog.html'))});}});
 assert.equal(facade.status().enabled,true);assert.equal((await facade.category()).data.length,2);assert.equal(calls,1);
 const engine=createLarozaEdge({fetchImpl:async()=>new Response(null,{status:301,headers:{location:'https://unreviewed.example/'}})});
 await assert.rejects(engine.category('series',1),e=>e.upstream_reason==='LAROZA_SOURCE_REDIRECT_REQUIRES_REVIEW');
 assert.equal(new URL(LAROZA_CONFIG.origin).hostname,LAROZA_CONFIG.pageHosts[0]);
 assert(!LAROZA_CONFIG.mediaHosts.includes('*.okprimeone.site'),'unreviewed media host expansion is prohibited');
});
