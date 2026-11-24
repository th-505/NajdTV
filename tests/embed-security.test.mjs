import assert from 'node:assert/strict';
import {test} from 'node:test';
import {fetchEmbedResponse, cascadeResolveStream, isValidDirectMediaUrl, unpackDeanEdwards, extractRawStreamsFromText} from '../server/scrapers/stream-unwrapper.mjs';
test('recursive embed resolver rejects private addresses and encoded bridges before network access',async()=>{
 for(const u of ['http://127.0.0.1/video.mp4','https://169.254.169.254/latest/meta-data','https://[::1]/embed/1','https://public.example/play?url='+Buffer.from('https://127.0.0.1/embed/1').toString('base64url')])assert.deepEqual(await cascadeResolveStream(u),[]);
 assert.equal(isValidDirectMediaUrl('https://127.0.0.1/video.mp4'),false);
 assert.equal(isValidDirectMediaUrl('https://user:pass@media.example/video.mp4'),false);
});
test('embed HTTP adapter validates redirect hops, DNS targets and decompressed body size',async()=>{
 let calls=0;const response=()=>{calls++;return new Response(null,{status:302,headers:{location:'https://169.254.169.254/latest/meta-data'}})};
 await assert.rejects(fetchEmbedResponse('https://embed.example/e/1',{fetchImpl:response}),/PRIVATE|LOCAL|UNSAFE/);assert.equal(calls,1);
 calls=0;await assert.rejects(fetchEmbedResponse('https://embed.example/e/1',{dnsLookupImpl:async()=>[{address:'127.0.0.1',family:4}],fetchImpl:async()=>{calls++;return new Response('bad')}}),/PRIVATE/);assert.equal(calls,0);
 await assert.rejects(fetchEmbedResponse('https://embed.example/e/1',{fetchImpl:async()=>new Response('x',{headers:{'content-length':String(9*1024*1024)}})}),/TOO_LARGE/);
});
test('untrusted packed metadata has bounded radix/count and literal substitutions',()=>{
 const packed=(radix,count,words,body='0')=>`eval(function(p,a,c,k,e,d){return p}('${body}',${radix},${count},'${words}'.split('|')))`;
 assert.equal(unpackDeanEdwards(packed(1,1,'bad')),'');
 assert.equal(unpackDeanEdwards(packed(62,999999999999,'bad')),'');
 assert.equal(unpackDeanEdwards(packed(2,1,'$&')),'$&');
 assert.equal(unpackDeanEdwards(packed(2,1,'safe')),'safe');
});

test('each embed redirect validates destination DNS before a follow-up request', async () => {
  for (const [status, privateIp] of [[301, '127.0.0.1'], [302, '10.0.0.1'],
    [307, '192.168.0.1'], [308, '::1']]) {
    const requests = [];
    const lookups = [];
    await assert.rejects(fetchEmbedResponse('https://embed.example/e/1', {
      dnsLookupImpl: async host => {
        lookups.push(host);
        return [{address: host === 'embed.example' ? '93.184.216.34' : privateIp}];
      },
      fetchImpl: async url => {
        requests.push(url);
        return new Response(null, {status, headers: {location: 'https://redirect.example/watch'}});
      },
    }), {code: 'UNSAFE_URL'});
    assert.deepEqual(lookups, ['embed.example', 'redirect.example']);
    assert.deepEqual(requests, ['https://embed.example/e/1']);
  }
});


test('media fixtures preserve the parent referrer and discard private links', () => {
  const parent = 'https://embed.example/watch';
  const html = '<source src="https://127.0.0.1/private.mp4"><source src="https://cdn.example/video.mp4">';
  const links = extractRawStreamsFromText(html, parent);
  assert.deepEqual(links.map(link => link.url), ['https://cdn.example/video.mp4']);
  assert.equal(links[0].headers.Referer, parent);
});

test('cascade skips an unsafe child and can read a later synthetic Base64 media reference', async () => {
  const root = 'https://embed.example/watch/root';
  const media = 'https://cdn.example/video.mp4';
  const b64 = Buffer.from(media).toString('base64url');
  const requests = [];
  const sources = await cascadeResolveStream(root, '', 0, new Set(), Date.now() + 2000, {
    dnsLookupImpl: async host => [{address: host === 'rejected.example' ? '127.0.0.1' : '93.184.216.34'}],
    fetchImpl: async url => {
      requests.push(url);
      return new Response(`<iframe src="https://rejected.example/embed/child"></iframe>
        <a href="/play?url=${b64}">Play</a>`);
    },
  });
  assert.deepEqual(requests, [root]);
  assert.deepEqual(sources.map(source => source.url), [media]);
  assert.equal(sources[0].headers.Referer, root);
});

test('synthetic packed literals can contain HLS metadata', () => {
  const packed = 'eval(function(p,a,c,k,e,d){return p}(\'"0"\',2,1,\'https://cdn.example/live.m3u8\'.split(\'|\')))';
  assert.deepEqual(extractRawStreamsFromText(packed).map(source => source.url), ['https://cdn.example/live.m3u8']);
});
