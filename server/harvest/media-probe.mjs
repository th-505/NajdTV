import {observedMp4Dimensions,mp4MetadataOffset} from '../../shared/mp4-video-dimensions.mjs';
import {observedContainer,mediaFormatFromUrl} from '../../shared/media-container.mjs';
import {observedHlsQualities,observedHlsInitialization} from './hls-quality.mjs';
import {fetchSafeResponse} from '../scrapers/shared/http.mjs';
import {probePinnedMedia} from '../pinned-playback.mjs';
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
 let quality_levels=hls?observedHlsQualities(playlist,playlistUrl):[];
 const adaptive=quality_levels.length>1;
 if(hls&&!quality_levels.length&&[200,206].includes(response.status)){
  const init=observedHlsInitialization(playlist,playlistUrl);
  if(init){
   const end=init.start+init.size-1;
   try{
    const result=await fetchImpl(init.url,{method:'GET',headers:{...headers,Range:`bytes=${init.start}-${end}`},
     responseType:'bytes',maxBytes:init.size,prefixBytes:init.size,allowHttp:false,
     allowedHosts:[init.hostname],maxRetries:0,maxRedirects:1,timeoutMs:4500,
     validateUrl:target=>{
      if(target.origin!==new URL(init.url).origin)throw Error('HLS_INIT_ORIGIN_CHANGED');
     }});
    const range=result.headers?.get?.('content-range')?.match(/^bytes (\d+)-(\d+)\/(?:\d+|\*)$/i);
    const verifiedRange=result.status===206&&Number(range?.[1])===init.start&&
     Number(range?.[2])===init.start+(result.bytes?.length||0)-1&&Number(range?.[2])<=end;
    const byteCount=result.bytes?.length||0;
    if(byteCount&&byteCount<=init.size&&
       (verifiedRange || (result.status===200&&init.start===0))){
     quality_levels=observedMp4Dimensions(result.bytes);
    }
   }catch{}
  }
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
