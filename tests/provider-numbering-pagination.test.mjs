import test from 'node:test';
import assert from 'node:assert/strict';
import {parseDetails} from '../server/providers/akoam.mjs';
import worker, {parseLarozaDetails, larozaRef} from '../edge/src/laroza.mjs';
import {boundedPage} from '../shared/provider-pagination.js';

test('legacy Akwam preserves large, missing and alternate source episode numbers', () => {
  const result = parseDetails('<a href="/episode/88/x">الحلقة 1216</a><a href="/episode/89/x">الحلقة 1217</a><a href="/episode/90/x">الحلقة 1217</a><a href="/episode/91/x">مشاهدة</a>');
  assert.deepEqual(result.episodes.map(e => e.episode_number), [1216,1217,1217,null]);
  assert.deepEqual(result.episodes.map(e => e.episode_id), ['88','89','90','91']);
  assert.equal(result.episodes.at(-1).watch_available, false);
});
test('Laroza episode offset resumes beyond 200, including multiple source areas', () => {
  const html = '<h1>مسلسل</h1><div class="SeasonsEpisodes">' + Array.from({length:205},(_,i)=>`<a href="/play.php?vid=e${i+1}">الحلقة ${i+1}</a>`).join('') + '</div>';
  const ref = larozaRef('/view-serie1.php?ser=example');
  const first = parseLarozaDetails(html,ref);
  assert.equal(first.episodes.length,200); assert.equal(first.partial,true); assert.equal(first.next_offset,200);
  const next = parseLarozaDetails(html,ref,undefined,first.next_offset);
  assert.deepEqual(next.episodes.map(e=>e.episode_number),[201,202,203,204,205]);
  assert.equal(next.partial,false); assert.equal(next.next_cursor,null);
});
test('catalog bounds always declare continuation at 60 and preserve remaining rows', () => {
  const rows = Array.from({length:65},(_,i)=>i);
  assert.equal(boundedPage(rows).next_offset,60);
  assert.deepEqual(boundedPage(rows,60).data,[60,61,62,63,64]);
  assert.equal(boundedPage(rows.slice(0,60)).partial,true);
});
