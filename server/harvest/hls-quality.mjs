import {assertSafeScraperUrl} from '../scrapers/shared/http.mjs';
/** Metadata from observed master entries only. The original master owns audio/subtitles. */
export function observedHlsVariants(text,baseUrl){
 if(typeof text!=='string'||text.length>65536||!text.trimStart().startsWith('#EXTM3U'))return[];
 const lines=text.split(/\r?\n/),levels=[];
 for(let i=0;i<lines.length&&levels.length<64;i++){
  if(!lines[i].startsWith('#EXT-X-STREAM-INF:'))continue;
  const attributes={};for(const match of lines[i].slice(18).matchAll(/([A-Z0-9-]+)=("[^"]*"|[^,]*)/g))attributes[match[1]]=match[2].replace(/^"|"$/g,'');
  const uri=lines[i+1]?.trim();if(!uri||uri.startsWith('#'))continue;
  let variantUrl;
  try{variantUrl=assertSafeScraperUrl(new URL(uri,baseUrl).href,{allowHttp:false}).href;}catch{continue;}
  const resolution=/^(\d{1,5})x(\d{1,5})$/.exec(attributes.RESOLUTION||'');
  const width=resolution?Number(resolution[1]):null,height=resolution?Number(resolution[2]):null;
  const bandwidth=Number(attributes['AVERAGE-BANDWIDTH']||attributes.BANDWIDTH)||null;
  if((width!==null&&(width<1||width>16384||height<1||height>16384))||(bandwidth!==null&&(!Number.isSafeInteger(bandwidth)||bandwidth<1||bandwidth>1000000000)))continue;
  levels.push({url:variantUrl,index:levels.length,width,height,bandwidth,codecs:String(attributes.CODECS||'').slice(0,256),label:height?`${height}p`:bandwidth?`${Math.round(bandwidth/1000)} kbps`:'تلقائي'});
 }
 return levels;
}

export function observedHlsQualities(text,baseUrl) {
 return observedHlsVariants(text,baseUrl).map(({url,...level})=>level);
}

/** Match only a public, same-origin initialization map. Never fetch segments to guess quality. */
export function observedHlsInitialization(text, playlistUrl) {
 if(typeof text!=='string'||text.length>65536||!text.trimStart().startsWith('#EXTM3U'))return null;
 try {
  const base=new URL(playlistUrl);
  const line=text.split(/\r?\n/).find(row=>row.startsWith('#EXT-X-MAP:'));
  if(!line)return null;
  const attributes=Object.fromEntries([...line.slice(11).matchAll(/([A-Z0-9-]+)=("[^"]*"|[^,]*)/g)]
   .map(([,key,value])=>[key,value.replace(/^"|"$/g,'')]));
  if(!attributes.URI)return null;
  const url=assertSafeScraperUrl(new URL(attributes.URI,base).href,{allowHttp:false,
   allowedHosts:[base.hostname]});
  if(url.origin!==base.origin)return null;
  const limit=65536;
  let start=0,size=limit;
  if(attributes.BYTERANGE!==undefined){
   const match=/^(\d+)@(\d+)$/.exec(attributes.BYTERANGE);
   if(!match)return null;
   size=Number(match[1]);start=Number(match[2]);
   if(!Number.isSafeInteger(size)||size<1||size>limit||!Number.isSafeInteger(start+size))return null;
  }
  return {url:url.href,hostname:url.hostname,start,size};
 }catch{return null;}
}
