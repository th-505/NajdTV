import http from 'node:http';
import {scrapeServers} from '../../server/browser/providers/sites/akwam.mjs';
import {fetchSafeResponse} from '../../server/scrapers/shared/http.mjs';
const source='https://akwam.ss/movie/638/the-intouchables';
let cache=null,pending=null,lastError=null,retryAt=0;
function expiry(url){const m=new URL(url).pathname.match(/\/download\/(\d{10})\//);return m?Number(m[1])*1000:null;}
async function resolve(){
 if(cache&&Date.now()<cache.refreshAt)return cache;
 if(pending)return pending;
 if(Date.now()<retryAt)throw Error('SOURCE_RETRY_COOLDOWN');
 pending=(async()=>{
  const servers=await scrapeServers(source,{strict:true,allowHttp:false,timeoutMs:8000,maxRetries:0,bridgeBudgetMs:20000,maxBridgeTargets:8});
  const streams=[];
  for(const s of servers){if(s.type!=='mp4'||streams.some(x=>x.quality.toLowerCase()===s.quality.toLowerCase()))continue;
   try{const r=await fetchSafeResponse(s.url,{headers:{...s.headers,Range:'bytes=0-1023'},allowHttp:false,timeoutMs:8000,maxRetries:0,responseType:'bytes',prefixBytes:1024});
    if(r.ok&&r.bytes?.includes(Buffer.from('ftyp')))streams.push({url:s.url,quality:s.quality,headers:s.headers,expiresAt:expiry(s.url)});
   }catch{}
  }
  if(!streams.length)throw Error('NO_VERIFIED_MP4');
  const now=Date.now(),earliest=Math.min(...streams.map(s=>s.expiresAt||now+3600000));
  cache={title:'The Intouchables',year:2011,checkedAt:new Date(now).toISOString(),refreshAt:Math.min(now+3600000,earliest-900000),expiryBasis:'inferred from source URL path; source may revoke earlier',streams};lastError=null;return cache;
 })().catch(e=>{lastError=e.code||'SOURCE_UNAVAILABLE';retryAt=Date.now()+60000;throw e;}).finally(()=>{pending=null;});return pending;
}
const server=http.createServer(async(req,res)=>{
 res.setHeader('Cache-Control','no-store');res.setHeader('X-Content-Type-Options','nosniff');
 const path=new URL(req.url,'http://localhost').pathname;
 if(req.method!=='GET'){res.writeHead(405).end();return;}
 if(path==='/health'){res.setHeader('Content-Type','application/json');res.end(JSON.stringify({status:'ok',lastSourceError:lastError,checkedAt:cache?.checkedAt||null}));return;}
 if(path==='/'){res.setHeader('Content-Type','text/html; charset=utf-8');res.end(`<!doctype html><html lang="ar" dir="rtl"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>The Intouchables</title><body style="background:#101014;color:#eee;font:18px sans-serif;margin:24px"><h1>The Intouchables (2011)</h1><p>جاري فحص المصدر وتجهيز رابط التشغيل…</p><video controls playsinline style="width:100%;max-height:75vh"></video><script>fetch('/api/intouchables').then(async r=>{if(!r.ok)throw Error();return r.json()}).then(d=>{const s=d.streams.find(s=>s.quality==='480p')||d.streams[0];document.querySelector('video').src=s.url;document.querySelector('p').textContent='الرابط جاهز. اضغط تشغيل.'}).catch(()=>document.querySelector('p').textContent='تعذر الوصول إلى المصدر. حاول بعد دقيقة.');</script></body></html>`);return;}
 if(path!=='/api/intouchables'&&path!=='/play'){res.writeHead(404).end();return;}
 try{const data=await resolve();if(path==='/play'){const s=data.streams.find(s=>s.quality==='480p')||data.streams[0];res.writeHead(302,{Location:s.url}).end();return;}
 res.setHeader('Content-Type','application/json');res.end(JSON.stringify(data));
 }catch{res.writeHead(503,{'Content-Type':'application/json','Retry-After':'60'}).end(JSON.stringify({status:'unavailable',reason:lastError}));}
});
server.listen(Number(process.env.PORT||10000),'0.0.0.0');

process.on('SIGTERM',()=>{server.close(()=>process.exit(0));setTimeout(()=>process.exit(0),10000).unref();});
