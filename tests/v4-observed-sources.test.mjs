import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';
import {observedContainer,mediaFormatFromUrl} from '../shared/media-container.mjs';
for(const family of ['najd','beta']){
 const prefix=family==='najd'?'../server/scrapers/sites/':'../server/browser/providers/sites/';
 const parser=await import(prefix+'3iskk.mjs'),moviz=await import(prefix+'moviztime.mjs');
 test(family+' observed portal keeps source seasons and separate dubbed/subtitled works',()=>{
  const hits=parser.parseSearch(fs.readFileSync('tests/fixtures/v4/turkxyz.html','utf8'));
  assert.equal(hits.length,6);assert(hits.some(h=>h.title.includes('مدبلج')));assert(hits.some(h=>h.title.includes('مترجم')));
  const detail=parser.parseDetails(fs.readFileSync('tests/fixtures/v4/xyzwork.html','utf8'),'https://3iskk.xyz/watch/tvshows/serie-kurtlar-vadisi-pusu-1oct5/');
  assert.deepEqual(detail.seasons.map(s=>s.season),[1,2]);assert.equal(detail.episodes.length,4);assert(detail.episodes.every(e=>e.number>1));
 });
 test(family+' Moviz ordinal and numbered season cards link only observed matching editions',()=>{
  const rows=moviz.observedMovizSeasons(fs.readFileSync('tests/fixtures/v4/moviz.html','utf8'),'https://moviz-time.surf/','أنمي One Piece مترجم الموسم 23 كامل');
  assert.equal(new Set(rows.map(r=>r.season)).size,23);assert(rows.some(r=>r.season===1&&r.url.includes('%d8%a7%d9%84%d8%a3%d9%88%d9%84')));assert(rows.every(r=>r.title.toLowerCase().includes('one piece')));
 });
}
test('container signatures do not turn HTML or unknown binary data into playable video',()=>{
 assert.equal(observedContainer(Buffer.from('<html>mp4</html>')),null);
 assert.equal(observedContainer(Buffer.from('#EXTM3U\n#EXT-X-VERSION:3')),'hls');
 assert.equal(observedContainer(Buffer.from('RIFF0000AVI data')),'avi');
 assert.equal(observedContainer(Buffer.from('<?xml version="1.0"?><MPD xmlns="urn:mpeg:dash:schema:mpd:2011">')),'dash');
 for(const ext of ['webm','mkv','mpd','mov','avi','ts','mp4'])assert.equal(mediaFormatFromUrl('https://cdn.example/video.'+ext+'?signed=private'),ext);
 assert.equal(mediaFormatFromUrl('https://cdn.example/file.php?ad=movie.mp4'),null);
});
