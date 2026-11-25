import test from 'node:test';
import assert from 'node:assert/strict';
import {getProvider as core} from '../server/scrapers/registry.mjs';
import {getProvider as beta} from '../server/browser/registry.mjs';

const site='https://www.atv.com.tr';
const host='https://httxxkbiqd.erbvr.com';
const cdn='https://httxxkbiqd.fdc.ercdn.net';
for (const [family,get] of [['Core',core],['Beta',beta]]) {
  test(family+' ATV indexes source episode numbers and probes the official MP4',async()=>{
    const atv=get('atv-tr').module;
    const fetchImpl=async (raw,init)=>{
      const u=new URL(raw);
      if (u.href===site+'/osman/bolumler') return new Response('<h1>Osman</h1><a href="/osman/187-bolum/izle">187</a><a href="/other/300-bolum/izle">300</a>');
      if (u.href===site+'/osman/187-bolum/izle') return new Response(`<script type="application/ld+json">{"@type":"VideoObject","contentUrl":"${host}/video_1080p.mp4"}</script>`);
      if (u.origin===host) return new Response(null,{status:302,headers:{location:cdn+'/video_1080p.mp4'}});
      assert.equal(u.origin,cdn);
      assert.equal(new Headers(init.headers).get('range'),'bytes=0-1023');
      return new Response(new Uint8Array([0,0,0,8,102,116,121,112]),{status:206,headers:{'content-type':'video/mp4'}});
    };
    const details=await atv.scrapeDetails(site+'/osman',{fetchImpl});
    assert.deepEqual(details.episodes.map(x=>x.number),[187]);
    const result=await atv.resolveStream(details.episodes[0].ref,{fetchImpl});
    assert.equal(result.ok,true);
    assert.equal(result.servers[0].quality,'1080p');
  });
}

for (const [family,get] of [['Core',core],['Beta',beta]]) {
  test(family+' ATV matches dotted and dotless Turkish letters and removes the series heading suffix',async()=>{
    const atv=get('atv-tr').module;
    const fetchImpl=async raw=>new Response(new URL(raw).pathname.endsWith('/bolumler')
      ? '<h1>ALTI ÜSTÜ İSTANBUL DİZİSİ</h1>'
      : '<div class="category-classic-item"><a href="/alti-ustu-istanbul"><img alt="Altı Üstü İstanbul"></a></div>');
    const results=await atv.scrapeSearch('alti üstü istanbul',1,{fetchImpl});
    assert.equal(results.length,1);
    assert.equal((await atv.scrapeDetails(results[0].ref,{fetchImpl})).title,'ALTI ÜSTÜ İSTANBUL');
  });
}
