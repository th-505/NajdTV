import test from 'node:test';
import assert from 'node:assert/strict';
import * as main from '../server/scrapers/sites/akwam.mjs';
import * as beta from '../server/browser/providers/sites/akwam.mjs';
import {resolveProviderMedia} from '../server/scrapers/shared/provider-media.mjs';

const root='https://akwam.ss/movie/42/observed';
const fixtures={
 [root]:'<h1>Movie</h1><video><source src="https://cdn.example/dead.mp4"></video>'+Array.from({length:8},(_,n)=>`<a href="https://akwam.ss/watch/quality-${n}">${n}p</a>`).join(''),
 ...Object.fromEntries(Array.from({length:8},(_,n)=>[`https://akwam.ss/watch/quality-${n}`,`<video><source src="https://cdn.example/quality-${n}.mp4" size="${n}"></video>`])),
};

for(const [name,provider]of [['main',main],['beta',beta]]){
 test(`${name} Akwam retains later observed qualities even when the page already contains a direct link`,async()=>{
  const servers=await provider.scrapeServers(root,{fixtures});
  assert.equal(servers._meta.bridge_targets,8);assert.equal(servers._meta.bridge_attempted,8);assert.equal(servers._meta.server_scan_complete,true);
  assert(servers.some(s=>s.url==='https://cdn.example/quality-7.mp4'));
  const resolved=await resolveProviderMedia({module:{scrapeServers:()=>provider.scrapeServers(root,{fixtures})}},root,{accept:async rows=>rows.filter(s=>s.url==='https://cdn.example/quality-7.mp4')});
  assert.equal(resolved.length,1);assert.equal(resolved[0].url,'https://cdn.example/quality-7.mp4');
 });
 test(`${name} Akwam exposes an incomplete bounded scan rather than false absence`,async()=>{
  const servers=await provider.scrapeServers(root,{fixtures,maxBridgeTargets:4});
  assert.equal(servers._meta.bridge_targets,8);assert.equal(servers._meta.bridge_attempted,4);assert.equal(servers._meta.server_scan_complete,false);
  await assert.rejects(resolveProviderMedia({module:{scrapeServers:()=>provider.scrapeServers(root,{fixtures,maxBridgeTargets:4})}},root,{accept:async()=>[]}),error=>error.code==='MEDIA_SERVER_SCAN_PARTIAL');
 });
 test(`${name} Akwam primary resolver retains the alternative source list for downstream failover`,async()=>{
  const resolved=await provider.resolveStream(root,{fixtures});
  assert.equal(resolved.url,'https://cdn.example/dead.mp4');
  assert(resolved.servers.some(s=>s.url==='https://cdn.example/quality-7.mp4'));
 });
}

for (const [family, provider] of [['Core', main], ['Beta', beta]]) {
  test(`${family} Akwam does not advertise invented resolutions or auto quality`, async () => {
    const [first, second] = await provider.scrapeServers(root, { fixtures: {
      [root]: '<video><source src="https://cdn.example/unknown.m3u8"><source src="https://cdn.example/known.mp4" size="720"></video>',
    } });
    assert.equal(first.quality, null);
    assert.equal(first.adaptive, undefined);
    assert.equal(second.quality, '720p');
    assert.equal(first.name, second.name);
    assert.equal((await provider.resolveStream('https://cdn.example/test.mp4')).quality, null);
  });
}

for (const [family, provider] of [['Core', main], ['Beta', beta]]) {
  test(`${family} Akwam resolves a relative watch action against the final work URL`, async () => {
    const finalUrl = 'https://ak.sv/movie/42/observed/';
    const watchUrl = 'https://ak.sv/movie/42/observed/watch/primary';
    const requests = [];
    const rows = await provider.scrapeServers(root, {
      maxRetries: 0,
      fetchImpl: async value => {
        const url = new URL(value).href;
        requests.push(url);
        if (url === root) return new Response(null, { status: 302, headers: { location: finalUrl } });
        if (url === finalUrl) return new Response('<a href="./watch/primary">مشاهدة</a>');
        assert.equal(url, watchUrl);
        return new Response('<video><source src="https://cdn.example/observed.mp4" size="720"></video>');
      },
    });
    assert.deepEqual(requests, [root, finalUrl, watchUrl]);
    assert.equal(rows[0].url, 'https://cdn.example/observed.mp4');
    assert.equal(rows[0].quality, '720p');
    assert.equal(rows[0].headers.Referer, watchUrl);
  });
}

for (const [family, provider] of [['Core', main], ['Beta', beta]]) {
  test(`${family} Akwam groups qualities by delivery host within the source`, async () => {
    const rows = await resolveProviderMedia({
      module: {
        scrapeServers: () => provider.scrapeServers(root, { fixtures: {
          [root]: '<video>' +
            '<source src="https://one.example/low.mp4" size="360">' +
            '<source src="https://one.example/high.mp4" size="720">' +
            '<source src="https://two.example/high.mp4" size="720"></video>',
        } }),
      },
    }, root);
    assert.deepEqual(rows.map(row => [row.server_name, row.quality]), [
      ['one.example', '360p'], ['one.example', '720p'], ['two.example', '720p'],
    ]);
    assert.equal(rows[0].server_id, rows[1].server_id);
    assert.notEqual(rows[0].server_id, rows[2].server_id);
    assert.equal(rows._meta.playable_servers, 2);
  });
}
