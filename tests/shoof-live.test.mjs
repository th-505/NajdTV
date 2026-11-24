import test from 'node:test';
import assert from 'node:assert/strict';
import * as shoof from '../server/browser/providers/sites/shoof-live.mjs';
import {getProvider as beta} from '../server/browser/registry.mjs';
import {getProvider as core} from '../server/scrapers/registry.mjs';

const site = 'https://m1.shooflive.buzz';
const player = 'https://shooof.online';
const html = (text, status=200) => new Response(text,{status,headers:{'content-type':'text/html'}});
test('Shoof is registered only in Beta and follows observed Arabic search pagination', async () => {
  assert.equal(beta('shoof-live').meta.id,'shoof-live');
  assert.equal(core('shoof-live'),null);
  const search = await shoof.scrapeSearch('مسلسل',1,{fetchImpl:async raw => {
    assert.equal(new URL(raw).searchParams.get('s'),'مسلسل');
    return html('<main id="shooflive-smart-search"><div class="slv2-grid"><a class="slv2-card" href="/series/work/"><span class="slv2-name">مسلسل</span><div class="slv2-poster"><img data-src="/art.webp" src="placeholder.gif"></div></a></div><div class="slv2-pages"><a href="/search/%D9%85%D8%B3%D9%84%D8%B3%D9%84/?sp=2">2</a></div></main>');
  }});
  assert.equal(search[0].poster,site+'/art.webp');
  assert.equal(search._meta.next_page,2);
  await shoof.scrapeSearch('مسلسل',2,{fetchImpl:async raw => {
    assert.equal(new URL(raw).searchParams.get('sp'),'2');
    assert.equal(decodeURI(new URL(raw).pathname),'/search/مسلسل/');
    return html('<main id="shooflive-smart-search"></main>');
  }});
});

test('episode identity and pending state survive indexing without invented numbering', async () => {
  const details = await shoof.scrapeDetails(site+'/series/work/',{fixtureHtml:
    '<div class="singleSeries"><div class="info"><h1>العمل</h1></div></div>' +
    [1215,983].map(n=>'<article class="postEp"><a href="/episode/e'+n+'/"><span class="episodeNum">حلقة '+n+'</span><span class="title">العمل الموسم 4 الحلقة.</span></a>'+
    (n===1215?'سيتم إضافة الحلقة المطلوبة فور نزولها':'')+'</article>').join('')});
  assert.deepEqual(details.episodes.map(e=>[e.season,e.number,e.watch_available]),[[4,983,true],[4,1215,false]]);
});

test('public Alba menu follows all advertised servers and isolates a failed host', async () => {
  const requested=[];
  const names=['anafast.cyou','mp4plus.cyou','vidspeed.org','vk.com','voe.sx','anafast.cyou'];
  const menu = '<ul class="aplr-menu">'+names.map((host,i)=>
    '<li><a class="aplr-link '+(i===0?'active':'')+'" href="?serv='+(i+1)+'">Server '+(i+1)+'</a></li>').join('')+'</ul>';
  const iframe = src => '<div class="aplr-player-content"><iframe id="iframe" src="'+src+'"></iframe></div>';
  const fetchImpl=async raw=>{
    const u=new URL(raw);
    requested.push(u.pathname+u.search);
    if(u.href===site+'/movies/work/') return html('<main></main>');
    if(u.href===site+'/movies/work/servers/') return html('<iframe src="'+player+'/albaplayer/work"></iframe>');
    if(u.origin===player){
      const i=Number(u.searchParams.get('serv')||1)-1;
      return html(menu+iframe('https://'+names[i]+'/embed-'+i));
    }
    if(u.hostname==='vk.com') return html('Forbidden',403);
    return html('<script>const file="https://assets.example.com'+u.pathname+'/master.m3u8?token=public-fixture";</script>');
  };
  const result=await shoof.resolveStream(site+'/movies/work/',{fetchImpl});
  assert.equal(result.ok,true);
  assert.deepEqual(result.servers.map(s=>s.label),['Server 1','Server 2','Server 3','Server 5','Server 6']);
  assert.ok(result.servers.every(s=>s.streamType==='m3u8'&&s.headers.Referer));
  assert.ok(requested.includes('/albaplayer/work?serv=6'));
  assert.ok(shoof.getShoofDiagnostics().some(s=>s.server==='vk.com'&&s.successes===0));
});

test('an external work reference is rejected and embed redirects stay inside approved hosts', async () => {
  assert.throws(()=>shoof.decodeProviderRef('https://outside.test/movies/work/'),/SHOOF_INVALID_REFERENCE/);
  let called=false;
  const result=await shoof.resolveStream(site+'/movies/work/',{fetchImpl:async raw=>{
    const u=new URL(raw);
    if(u.origin===site) return html('<iframe src="'+player+'/albaplayer/work"></iframe>');
    if(u.origin===player) return html('<div class="aplr-player-content"><iframe src="https://anafast.cyou/embed"></iframe></div>');
    if(u.hostname==='anafast.cyou') return new Response(null,{status:302,headers:{location:'https://outside.test/content'}});
    called=true;
    return html('');
  }});
  assert.equal(called,false);
  assert.equal(result.ok,false);
});

test('expired observed media is discarded without altering the signed links', async () => {
  const issued = Math.floor(Date.now()/1000);
  const current = 'https://assets.example.com/live/master.m3u8?t=fixture&s='+issued+'&e=18000';
  const aged = 'https://assets.example.com/old/master.m3u8?t=fixture&s='+(issued-36000)+'&e=60';
  const result = await shoof.resolveStream(site+'/movies/work/',{fetchImpl:async raw=>{
    const u=new URL(raw);
    if(u.origin===site) return html('<iframe src="'+player+'/albaplayer/work"></iframe>');
    if(u.origin===player) return html('<div class="aplr-player-content"><iframe src="https://anafast.cyou/embed"></iframe></div>');
    return html('<script>let a="'+aged+'", b="'+current+'";</script>');
  }});
  assert.equal(result.servers.length,1);
  assert.equal(result.streamUrl,current);
  assert.equal(result.servers[0].expiresAt,(issued+18000)*1000);
});
