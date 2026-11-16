import test from 'node:test';import assert from 'node:assert/strict';
import {observedEpisodeMetadata,observedDurationSeconds} from '../server/scrapers/shared/episode-metadata.mjs';
import {normalizeEpisodeList} from '../server/scrapers/shared/normalize.mjs';
test('episode metadata accepts observed times and public images without inventing absent duration',()=>{
 assert.equal(observedDurationSeconds('46:20'),2780);assert.equal(observedDurationSeconds('٤٦:٢٠'),2780);
 assert.equal(observedDurationSeconds('1:03:20'),3800);assert.equal(observedDurationSeconds('PT46M20S'),2780);
 for(const value of ['2026','46:99','-1:00','PT','unknown'])assert.equal(observedDurationSeconds(value),null);
 assert.deepEqual(observedEpisodeMetadata({poster:'https://127.0.0.1/private',duration:'unknown'},'https://source.example'),{});
 const [row]=normalizeEpisodeList([{url:'/watch/episode-1',title:'الحلقة 1',duration:'46:20',thumbnail:'/thumb.jpg'}],{baseUrl:'https://source.example',allowHttp:false,providerId:'fixture'});
 assert.equal(row.duration_seconds,2780);assert.equal(row.poster,'https://source.example/thumb.jpg');
});
for(const [family,path]of [['najd','../server/scrapers/sites/ahwak.mjs'],['beta','../server/browser/providers/sites/ahwak.mjs']])test(family+' Ahwak retains observed episode images and clocks through repeated normalization',async()=>{
 const mod=await import(path);const html='<h1>مسلسل Fixture الموسم الاول</h1><div class="SeasonsEpisodesMains"><div class="tabcontent" id="Season1"><div class="thumbnail"><span class="pm-label-duration">46:20</span><a href="watch.php?vid=fixture" title="الحلقة 1"><img data-echo="/uploads/thumbs/fixture.jpg"></a></div></div></div>';
 const d=mod.parseAhwakDetails(html,'https://yam.ahwaktv.net/view-serie.php?name=fixture');
 assert.equal(d.episodes.length,1);assert.equal(d.episodes[0].duration_seconds,2780);assert.equal(d.episodes[0].poster,'https://yam.ahwaktv.net/uploads/thumbs/fixture.jpg');
});
for(const [family,path]of [['najd','../server/harvest/episode-index.mjs'],['beta','../server/browser/episode-index.mjs']])test(family+' observed episode graph preserves optional metadata while retaining actual source numbering',async()=>{
 const {scanEpisodeIndex}=await import(path);const result=scanEpisodeIndex('<h1>Fixture</h1>','https://source.example/series',{provider:'fixture',domains:['source.example'],episodes:[{url:'/episode-19',title:'الحلقة 19',number:19,poster:'/19.jpg',duration:'46:20'}]});
 assert.equal(result.episodes[0].episode,19);assert.equal(result.episodes[0].duration_seconds,2780);assert.equal(result.episodes[0].poster,'https://source.example/19.jpg');
});
