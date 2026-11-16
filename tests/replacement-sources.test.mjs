import test from 'node:test';import assert from 'node:assert/strict';
import * as najd from '../server/scrapers/registry.mjs';import * as beta from '../server/browser/registry.mjs';
import {PROVIDER_REPLACEMENTS} from '../server/scrapers/replacements.mjs';
import {isCloudflareOrAccessBlock} from '../server/scrapers/shared/errors.mjs';
const fixtures={
 animezid:{path:'/series/fixture/',html:'<article class="az-card"><a href="/series/fixture/"><img alt="Fixture series" src="/poster.jpg"><h3 class="az-card__title">Fixture series</h3></a></article>'},
 movizland:{path:'/fixture-movie/',html:'<div class="Block"><a href="/fixture-movie/"><img alt="Fixture 2024" data-src="/poster.jpg"></a><h2>Fixture 2024</h2></div>'},
 egybest:{path:'/movie/42/fixture',html:'<a class="postBlock" href="/movie/42/fixture"><img data-src="/poster.jpg"><h3 class="title">Fixture 2024</h3></a>'},
};
for(const [scope,family]of [['najd',najd],['beta',beta]]){
 test(scope+' explicitly replaces unavailable sources and preserves original stored reference handlers',()=>{
  const active=family.listProviders();assert.equal(active.length,25);
  for(const [old,replacement]of Object.entries(PROVIDER_REPLACEMENTS)){
   assert(!active.some(p=>p.id===old));assert(active.some(p=>p.id===replacement));assert(family.getProvider(old));
  }
 });
 for(const [id,fixture]of Object.entries(fixtures))test(scope+' '+id+' parses source-owned cards, relative links and rejects SSRF/reference escapes',async()=>{
  const entry=family.getProvider(id),mod=entry.module,origin=entry.meta.domains[0];
  const rows=await mod.scrapeSearch('Fixture',1,{fixtureHtml:fixture.html});
  assert.equal(rows.length,1);assert.equal(rows[0].source,id);assert(rows[0].ref.startsWith(id+':'));
  assert.equal(mod.decodeProviderRef(rows[0].ref),origin+fixture.path);
  assert.equal(mod.decodeProviderRef(fixture.path),origin+fixture.path);
  for(const value of ['https://127.0.0.1'+fixture.path,'https://user:secret@'+new URL(origin).hostname+fixture.path,'https://evil.example'+fixture.path,'//evil.example'+fixture.path])assert.throws(()=>mod.decodeProviderRef(value));
  const details=await mod.scrapeDetails(rows[0].ref,{fixtureHtml:'<h1>Fixture 2024</h1><meta property="og:image" content="/poster.jpg">'});
  assert.equal(details.title,'Fixture 2024');assert.equal(details.servers.length,0);
  const unavailable=await mod.resolveStream(rows[0].ref,{fixtureHtml:'<h1>Fixture</h1><iframe src="https://ads.example/ad"></iframe>'});
  assert.equal(unavailable.ok,false);assert.equal(unavailable.url,null);
 });
}
test('200 Bot Verification and LiteSpeed CAPTCHA are access failures, not empty successful catalogs',()=>{
 assert.equal(isCloudflareOrAccessBlock(200,'<title>Bot Verification</title><form action="/.lsrecap/recaptcha?"></form>'),true);
 assert.equal(isCloudflareOrAccessBlock(200,'<h1>Ordinary content</h1>'),false);
});
for(const [scope,path]of [['najd','../server/harvest/episode-index.mjs'],['beta','../server/browser/episode-index.mjs']])test(scope+' source-owned season routes replace the latest rail without borrowing another work',async()=>{
 const {scanEpisodeIndex}=await import(path);
 const html='<h1>Naruto</h1><a href="/series/naruto/season/1/">Naruto season one</a><a href="/series/naruto/season/2/">Naruto Shippuden</a><a href="/series/other/season/2/">Other work</a><a href="/watch.php?vid=latest">الحلقة 500</a>';
 const graph=scanEpisodeIndex(html,'https://animezid.org/series/naruto/',{provider:'animezid',domains:['animezid.org'],title:'Naruto'});
 assert.equal(graph.episodes.length,0);
 assert.deepEqual(graph.pages.sort(),['https://animezid.org/series/naruto/season/1/','https://animezid.org/series/naruto/season/2/']);
});

for(const [scope,family]of [['najd',najd],['beta',beta]])test(scope+' AnimeZid reports an observed external watch gateway instead of false empty media',async()=>{
 const mod=family.getProvider('animezid').module;
 await assert.rejects(mod.scrapeServers('https://animezid.org/watch.php?vid=fixture',{
  fixtureHtml:'<h1>Fixture</h1><a class="az-cinema-button--primary" href="https://gateway.example/skip?post=fixture">شاهد وحمّل الآن</a>'
 }),error=>error.code==='UNSUPPORTED_CAPABILITY' && error.message==='SOURCE_EXTERNAL_WATCH_GATEWAY');
});
for(const [scope,family]of [['najd',najd],['beta',beta]])test(scope+' observed resolver retains the fifth and later public media servers',async()=>{
 const mod=family.getProvider('animezid').module;
 const links=Array.from({length:6},(_,i)=>`https://media.example.com/server-${i+1}.mp4`);
 const result=await mod.resolveStream('https://animezid.org/watch.php?vid=fixture',{
  fixtureHtml:`<h1>Fixture</h1><div id="player"><script>const observed=${JSON.stringify(links)};</script></div>`
 });
 assert.equal(result.ok,true);
 assert.equal(result.servers.length,6);
 assert.deepEqual(new Set(result.servers.map(row=>row.url)),new Set(links));
});
