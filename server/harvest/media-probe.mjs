import {observedContainer} from '../../shared/media-container.mjs';
import {observedHlsQualities} from './hls-quality.mjs';
import {fetchSafeResponse} from '../scrapers/shared/http.mjs';
import {probePinnedMedia} from '../pinned-playback.mjs';
/** Header checks alone accept dead CDN placeholders. Require actual container bytes. */
export async function probeHarvestMedia(candidate,{platform='native',fetchImpl=fetchSafeResponse,headProbe=probePinnedMedia}={}){
 const head=await headProbe(candidate,{platform});
 if(![200,206].includes(head.statusCode))return head;
 const browserOrigin='https://th-505.github.io';
 const headers=platform==='web'?{Origin:browserOrigin,Referer:browserOrigin+'/'}:candidate.headers;
 const response=await fetchImpl(candidate.url,{method:'GET',headers:{...headers,Range:'bytes=0-32767'},responseType:'bytes',maxBytes:65536,prefixBytes:32768,allowHttp:false,maxRetries:0,maxRedirects:2,timeoutMs:8000});
 const bytes=response.bytes||Buffer.alloc(0);
 const mp4=bytes.length>=12&&bytes.subarray(4,8).toString('ascii')==='ftyp';
 const hls=bytes.subarray(0,256).toString('utf8').trimStart().startsWith('#EXTM3U');
 // Some real CDNs omit Content-Type even on successful HEAD and GET. Their
 // actual container signature is stronger evidence than the absent MIME label.
 const container=observedContainer(bytes);
 const quality_levels=hls?observedHlsQualities(bytes.toString('utf8'),candidate.url):[];
 const playable=[200,206].includes(response.status)&&Boolean(container);
 const allowedOrigin=response.headers?.get?.('access-control-allow-origin');
 // The browser-context GET and actual bytes are stronger evidence than a
 // missing/generic HEAD MIME type. Native-only headers cannot certify the web.
 const webPlayable=platform==='web'?playable&&['mp4','hls','webm','ogg'].includes(container)&&[browserOrigin,'*'].includes(allowedOrigin):playable&&head.webPlayable===true;
 return {...head,container,quality_levels,adaptive:quality_levels.length>0,playable,statusCode:response.status,webPlayable,container_verified:playable,verification_basis:'bounded-container-bytes'};
}
