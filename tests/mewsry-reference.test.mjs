import test from 'node:test';
import assert from 'node:assert/strict';
import {resolveStream} from '../server/scrapers/sites/mewsry.mjs';
test('Syria Live resolver decodes its own references before validating the URL', async () => {
 const url='https://media.example.com/channel.m3u8';
 const ref='mewsry:'+Buffer.from(url).toString('base64url');
 const result=await resolveStream(ref,{skipProbe:true});
 assert.equal(result.streamUrl,url);
 assert.equal(result.type,'m3u8');
 assert.equal(result.verified,false,'a skipped network probe is not playback verification');
});
test('Syria Live encoded private-address references remain blocked', async () => {
 const ref='mewsry:'+Buffer.from('http://127.0.0.1/channel.m3u8').toString('base64url');
 await assert.rejects(resolveStream(ref,{skipProbe:true}));
});

for (const modulePath of [
  '../server/scrapers/sites/mewsry.mjs',
  '../server/browser/providers/sites/mewsry.mjs',
]) {
  test(`Syria Live resolves the exact scheduled match in ${modulePath}`, async () => {
    const { parseMatchesFromHtml, scrapeDetails } = await import(modulePath);
    const html = [125, 240].map(timestamp => `
      <div class="eni-match">
        <div class="eni-team-home"><span>الفريق الأول</span></div>
        <div class="eni-team-away"><span>الفريق الثاني</span></div>
        <div class="eni-kickoff" data-ts="${timestamp}"></div>
      </div>`).join('');
    const rows = parseMatchesFromHtml(html);
    const options = { fixtureHtml: html };
    const details = await scrapeDetails(rows[1].ref, options);
    assert.equal(details.id, rows[1].id);
    assert.equal(details.timestamp, 240);
    assert.equal(details.title, rows[1].title);
    const archive = parseMatchesFromHtml(html, undefined, 'yesterday');
    const archived = await scrapeDetails(archive[1].ref, options);
    assert.equal(new URL(archived.url).searchParams.get('match_day'), 'yesterday');
    assert.equal(archived.timestamp, 240);
    const missing = await scrapeDetails(rows[1].ref.replace(/:240$/, ':999'), options);
    assert.equal(missing._meta.ok, false);
  });
}
