import test from 'node:test';
import assert from 'node:assert/strict';
import { createLiveCatalog, parseLivePlaylist, LIVE_GROUPS } from '../server/live-catalog.mjs';
const feed = '#EXTM3U\n#EXTINF:-1 tvg-id="AlEkhbariya.sa" tvg-logo="https://images.example.com/logo.png",السعودية\nhttps://cdn.example.com/live/index.m3u8\n';
test('Gulf and requested programme groups, deduplicated streams and no private/insecure URLs', () => {
  assert.deepEqual(LIVE_GROUPS.map(g => g.id), ['ae', 'sa', 'kw', 'qa', 'bh', 'om', 'movies', 'series', 'news', 'kids', 'religious']);
  const parsed = parseLivePlaylist(feed + feed.replace('#EXTM3U\n', '') +
    '#EXTINF:-1,private\nhttps://127.0.0.1/live.m3u8\n#EXTINF:-1,insecure\nhttp://cdn.example.com/live.m3u8\n#EXTINF:-1,credentials\nhttps://u:p@cdn.example.com/a.m3u8\n#EXTINF:-1,script\njavascript:alert(1)\n');
  assert.equal(parsed.channels.length, 1);
  assert.equal(parsed.channels[0].streams.length, 1);
  assert.equal(parsed.skipped, 4);
  assert.throws(() => parseLivePlaylist('<html>error</html>'), /INVALID_PLAYLIST/);
});
test('50 concurrent readers share one bounded fetch; every play opens a distinct session', async () => {
  let calls = 0;
  const catalog = createLiveCatalog({ fetchPlaylist: async url => { calls++; assert.equal(url, LIVE_GROUPS[1].url); await new Promise(r => setTimeout(r, 10)); return feed; } });
  const pages = await Promise.all(Array.from({ length: 50 }, () => catalog.catalog({ group: 'sa' })));
  assert.equal(calls, 1);
  assert.equal(pages[0].data[0].streams, undefined);
  const ref = pages[0].data[0].ref;
  const sessions = await Promise.all(Array.from({ length: 50 }, () => catalog.playback(ref)));
  assert.equal(new Set(sessions.map(s => s.data.playback_session)).size, 50);
  assert.equal(sessions[0].data.playback_mode, 'direct');
  await assert.rejects(catalog.playback('https://127.0.0.1/a'), /BAD_REFERENCE/);
  await assert.rejects(catalog.catalog({ group: 'arbitrary' }), /UNKNOWN_GROUP/);
  await assert.rejects(catalog.catalog({ page: Infinity }), /BAD_QUERY/);
});
test('TTL refresh serves stale channels and unavailable feeds cool down without retry storms', async () => {
  let time = 1000, calls = 0, fail = false;
  const catalog = createLiveCatalog({ now: () => time, fetchPlaylist: async () => { calls++; if (fail) throw Error('network'); return feed; } });
  await catalog.catalog(); fail = true; time += 12 * 3600000 + 1;
  const stale = await catalog.catalog(); assert.equal(stale.stale, true);
  await new Promise(r => setImmediate(r));
  await Promise.all(Array.from({ length: 20 }, () => catalog.catalog()));
  assert.equal(calls, 2);
  time += 24 * 3600000;
  await assert.rejects(catalog.catalog(), /UNAVAILABLE/);
  await assert.rejects(catalog.catalog(), /UNAVAILABLE/);
  assert.equal(calls, 3);
});
test('pagination and search retain stable references without leaking stream URLs', async () => {
  const text = '#EXTM3U\n' + Array.from({ length: 125 }, (_, i) => `#EXTINF:-1 tvg-id="AlEkhbariya.sa@${i}",Channel ${i}\nhttps://cdn.example.com/${i}.m3u8`).join('\n');
  const catalog = createLiveCatalog({ fetchPlaylist: async () => text });
  const first = await catalog.catalog(), last = await catalog.catalog({ page: 3 });
  assert.equal(first.data.length, 60); assert.equal(last.data.length, 5);
  assert.equal(last.pagination.has_more, false);
  const filtered = await catalog.catalog({ q: 'Channel 124' });
  assert.equal(filtered.data[0].ref, last.data[4].ref);
  assert.ok(!JSON.stringify(first).includes('cdn.example.com'));
});
test('explicit playback retry refreshes public feed metadata once, without a source retry storm', async () => {
 let calls=0;
 const catalog=createLiveCatalog({fetchPlaylist:async()=>{calls++;await new Promise(r=>setTimeout(r,5));return feed.replace('index.m3u8',`version-${calls}.m3u8`);}});
 const ref=(await catalog.catalog()).data[0].ref;
 const first=await catalog.playback(ref);
 const retries=await Promise.all(Array.from({length:50},()=>catalog.playback(ref,true)));
 assert.equal(calls,2);
 assert.notEqual(first.data.media_path,retries[0].data.media_path);
 assert(retries.every(row=>row.data.media_path===retries[0].data.media_path));
 await catalog.playback(ref,true);assert.equal(calls,2);
});

test('Gulf feeds exclude unrelated, unreviewed and mismatched channel identities', async () => {
  const extra = ['BTLTV.nl', 'SharjahSports.ae', 'Unknown.sa', 'AlQuranAlKareemTV.sa']
    .map(id => `#EXTINF:-1 tvg-id="${id}",${id}\nhttps://cdn.example.com/${id}.m3u8\n`).join('');
  const catalog = createLiveCatalog({fetchPlaylist: async () => feed + extra});
  assert.deepEqual((await catalog.catalog({group:'news'})).data.map(row=>row.title), ['السعودية']);
  assert.deepEqual((await catalog.catalog({group:'religious'})).data.map(row=>row.title), ['AlQuranAlKareemTV.sa']);
  assert.equal((await catalog.catalog({group:'sa'})).data.length, 2);
  assert.equal((await catalog.catalog({group:'ae'})).data.length, 0);
});
