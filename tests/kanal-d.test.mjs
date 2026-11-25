import test from 'node:test';
import assert from 'node:assert/strict';
import {getProvider as core} from '../server/scrapers/registry.mjs';
import {getProvider as beta} from '../server/browser/registry.mjs';

const site='https://www.kanald.com.tr';
const cdn='https://kanaldvod.duhnet.tv';
const work=site+'/kanit';
const episode=work+'/bolumler/100-bolum-izle';
const embed=site+'/embed/5465efdfcf45af1064b71fca';
const manifest=cdn+'/S1/HLS_VOD/preview/index.m3u8';
const video=(value)=>'<script type="application/ld+json">'+JSON.stringify({
  '@type':'https://schema.org/VideoObject',...value,
})+'</script>';
for (const [family,get] of [['Core',core],['Beta',beta]]) {
  test(family+' Kanal D preserves episode numbers and resolves the published HLS',async()=>{
    const module=get('kanal-d').module;
    const fetchImpl=async raw=>{
      if (raw===work+'/bolumler') return new Response('<meta property="og:title" content="Kanıt Tüm Bölümler (İlk Bölüm, Son Bölüm) - Kanal D"><h1>TÜM Bölümler</h1><a href="'+episode+'">100</a>');
      if (raw===work) return new Response('<meta property="og:image" content="https://image.kanald.com.tr/poster.webp">');
      if (raw===episode) return new Response(video({embedUrl:embed}));
      if (raw===embed) return new Response('MediaCdnDomainUrl: "'+cdn+'",'+video({contentUrl:'S1/HLS_VOD/preview/index.m3u8'}));
      assert.equal(raw,manifest);
      return new Response('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=240000\nvideo.m3u8\n');
    };
    const result=await module.scrapeDetails(work,{fetchImpl});
    assert.deepEqual(result.episodes.map(x=>x.number),[100]);
    assert.equal(result.title,'Kanıt');
    assert.equal(result.poster,'https://image.kanald.com.tr/poster.webp');
    const playback=await module.resolveStream(result.episodes[0].ref,{fetchImpl});
    assert.equal(playback.ok,true);
    assert.equal(playback.streamUrl,manifest);
  });
  test(family+' rejects an unapproved media host without fetching it',async()=>{
    const module=get('kanal-d').module;
    const fetchImpl=async raw=>{
      if (raw===episode) return new Response(video({embedUrl:embed}));
      assert.equal(raw,embed);
      return new Response('MediaCdnDomainUrl: "https://other.example",'+video({contentUrl:'S1/HLS_VOD/preview/index.m3u8'}));
    };
    assert.equal((await module.resolveStream(episode,{fetchImpl})).ok,false);
  });
}

for (const [family,get] of [['Core',core],['Beta',beta]]) {
  test(family+' retains the names and episode references of newer Kanal D series',async()=>{
    const module=get('kanal-d').module;
    const result=await module.scrapeDetails(site+'/daha-17',{fixtureHtml:
      '<title>Bölümler - Daha 17</title><meta property="og:title" content="Bölümler">'+
      '<h1>TÜM Bölümler</h1><a href="/daha-17/bolumler/daha-17-9-bolum">9</a>'+
      '<a href="/daha-17/bolumler/daha-17-ilk-bolum">İlk Bölüm</a>'+
      '<a href="/other/bolumler/other-3-bolum">Other</a>'});
    assert.equal(result.title,'Daha 17');
    assert.deepEqual(result.episodes.map(x=>x.number),[1,9]);
  });
}

for (const [family,get] of [['Core',core],['Beta',beta]]) {
  test(family+' prefers the official HLS linked directly from the episode',async()=>{
    const module=get('kanal-d').module;
    const playlist=cdn+'/hls/series/episode.smil/playlist.m3u8';
    const fetchImpl=async raw=>{
      if (raw===episode) return new Response(video({contentUrl:playlist,embedUrl:embed}));
      assert.equal(raw,playlist);
      return new Response('#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=240000\nvideo.m3u8\n');
    };
    assert.equal((await module.resolveStream(episode,{fetchImpl})).streamUrl,playlist);
  });
}
