import {observedMp4Dimensions,mp4MetadataOffset} from '../../shared/mp4-video-dimensions.mjs';
import {observedContainer,mediaFormatFromUrl} from '../../shared/media-container.mjs';
import {observedHlsVariants,observedHlsInitialization} from './hls-quality.mjs';
import {fetchSafeResponse} from '../scrapers/shared/http.mjs';
import {probePinnedMedia} from '../pinned-playback.mjs';
async function playlistRequest(url,origin,range,maxBytes,headers,fetchImpl) {
 const target=new URL(url);
 if(target.origin!==origin)return null;
 try{
  const response=await fetchImpl(url,{method:'GET',headers:{...headers,Range:range},responseType:'bytes',
   maxBytes,prefixBytes:maxBytes,allowHttp:false,allowedHosts:[target.hostname],maxRetries:0,
   maxRedirects:1,timeoutMs:3500,validateUrl:destination=>{
    if(destination.origin!==origin)throw Error('HLS_ORIGIN_CHANGED');
   }});
  if([200,206].includes(response.status))return response;
 }catch{}
 return null;
}

async function initializationQualities(playlist,playlistUrl,headers,fetchImpl) {
 const init=observedHlsInitialization(playlist,playlistUrl);
 if(!init)return [];
 const end=init.start+init.size-1;
 const result=await playlistRequest(init.url,new URL(playlistUrl).origin,
  `bytes=${init.start}-${end}`,init.size,headers,fetchImpl);
 if(!result)return [];
 const byteCount=result.bytes?.length||0;
 const range=result.headers?.get?.('content-range')?.match(/^bytes (\d+)-(\d+)\/(?:\d+|\*)$/i);
 const verifiedRange=result.status===206&&Number(range?.[1])===init.start&&
  Number(range?.[2])===init.start+byteCount-1&&Number(range?.[2])<=end;
 if(byteCount&&byteCount<=init.size&&(verifiedRange||(result.status===200&&init.start===0))){
  return observedMp4Dimensions(result.bytes);
 }
 return [];
}

async function verifyPlaylistQualities(playlist,playlistUrl,headers,fetchImpl) {
 const variants=observedHlsVariants(playlist,playlistUrl);
 if(!variants.length)return {adaptive:false,levels:await initializationQualities(playlist,playlistUrl,headers,fetchImpl)};
 const origin=new URL(playlistUrl).origin;
 const unresolved=variants.filter(level=>!level.height&&new URL(level.url).origin===origin);
 const targets=[...new Set(unresolved.map(level=>level.url))];
 // Allow up to two parallel metadata checks to preserve the playback budget.
 const selected=targets.length>1 ? [targets[0],targets.at(-1)] : targets;
 const dimensions=new Map(await Promise.all(selected.map(async url=>{
  const response=await playlistRequest(url,origin,'bytes=0-8191',8192,headers,fetchImpl);
  if(!response?.bytes?.length)return [url,null];
  const levels=await initializationQualities(Buffer.from(response.bytes).toString('utf8'),response.url||url,headers,fetchImpl);
  return [url,levels[0]||null];
 })));
 return {adaptive:variants.length>1,levels:variants.map(({url,...level})=>({...level,...(dimensions.get(url)||{})}))};
}

/** Header checks alone accept dead CDN placeholders. Require actual container bytes. */
export async function probeHarvestMedia(candidate,{platform='native',origin='https://th-505.github.io',fetchImpl=fetchSafeResponse,headProbe=probePinnedMedia}={}){
 const head=await headProbe(candidate,{platform,origin});
 if(![200,206].includes(head.statusCode))return head;
 const browserOrigin=origin;
 const plainVideo=['mp4','m4v','webm','ogv'].includes(mediaFormatFromUrl(candidate.url));
 const headers=platform==='web'?{...(plainVideo?{}:{Origin:browserOrigin}),Referer:browserOrigin+'/'}:candidate.headers;
 const response=await fetchImpl(candidate.url,{method:'GET',headers:{...headers,Range:'bytes=0-32767'},omitOrigin:platform==='web'&&plainVideo,responseType:'bytes',maxBytes:65536,prefixBytes:32768,allowHttp:false,maxRetries:0,maxRedirects:2,timeoutMs:8000});
 const bytes=response.bytes||Buffer.alloc(0);
 const hls=bytes.subarray(0,256).toString('utf8').trimStart().startsWith('#EXTM3U');
 // Some real CDNs omit Content-Type even on successful HEAD and GET. Their
 // actual container signature is stronger evidence than the absent MIME label.
 const container=observedContainer(bytes);
 const playlist=hls?bytes.toString('utf8'):'';
 const playlistUrl=response.url || candidate.url;
 let quality_levels=[];
 let adaptive=false;
 if(hls&&[200,206].includes(response.status)){
  const verified=await verifyPlaylistQualities(playlist,playlistUrl,headers,fetchImpl);
  quality_levels=verified.levels;
  adaptive=verified.adaptive;
 }
 if(container==='mp4'&&[200,206].includes(response.status)){
  quality_levels=observedMp4Dimensions(bytes);
  const length=Number(response.headers?.get?.('content-range')?.match(/^bytes 0-\d+\/(\d+)$/i)?.[1]);
  if(!quality_levels.length&&Number.isSafeInteger(length)&&length>bytes.length){
   const limit=65536, metadataOffset=mp4MetadataOffset(bytes,length);
   const start=metadataOffset??Math.max(0,length-limit),end=Math.min(start+limit,length)-1;
   try{
    const tail=await fetchImpl(candidate.url,{method:'GET',headers:{...headers,Range:`bytes=${start}-${end}`},
      omitOrigin:platform==='web'&&plainVideo,responseType:'bytes',maxBytes:limit,prefixBytes:limit,
      allowHttp:false,maxRetries:0,maxRedirects:2,timeoutMs:5000});
    if(tail.status===206&&tail.bytes?.length===end-start+1&&
      tail.headers?.get?.('content-range')===`bytes ${start}-${end}/${length}`){
     quality_levels=metadataOffset===null ? observedMp4Dimensions(bytes,tail.bytes) : observedMp4Dimensions(tail.bytes);
    }
   }catch{}
  }
 }
 const playable=[200,206].includes(response.status)&&Boolean(container);
 const allowedOrigin=response.headers?.get?.('access-control-allow-origin');
 const resourcePolicy=response.headers?.get?.('cross-origin-resource-policy')?.toLowerCase();
 const policyBlocked=['same-origin','same-site'].includes(resourcePolicy)&&new URL(candidate.url).origin!==browserOrigin;
 // The browser-context GET and actual bytes are stronger evidence than a
 // missing/generic HEAD MIME type. Native-only headers cannot certify the web.
 // HTML video loads plain MP4/WebM/Ogg in no-cors mode. HLS fetched by a JS
 // player still needs CORS. Test with frontend Referer, never source cookies.
 const webPlayable=platform==='web'?playable&&!policyBlocked&&(plainVideo?['mp4','webm','ogg'].includes(container):['mp4','hls','webm','ogg'].includes(container)&&[browserOrigin,'*'].includes(allowedOrigin)):playable&&head.webPlayable===true;
 return {...head,container,quality_levels,adaptive,playable,statusCode:response.status,webPlayable,container_verified:playable,verification_basis:'bounded-container-bytes'};
}
