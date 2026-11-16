import {resolveSafeUrl} from './http.mjs';
/** Pure observed metadata normalization, shared across independent site parsers. */
export function observedDurationSeconds(value) {
 if(typeof value!=='string'||value.length>80)return null;
 const text=value.trim().replace(/[٠-٩]/g,c=>String('٠١٢٣٤٥٦٧٨٩'.indexOf(c))).replace(/[۰-۹]/g,c=>String('۰۱۲۳۴۵۶۷۸۹'.indexOf(c)));
 let seconds=null;
 if(/^\d{1,3}:\d{2}(?::\d{2})?$/.test(text)){
  const parts=text.split(':').map(Number);if(parts.slice(1).some(x=>x>59))return null;
  seconds=parts.reduce((total,n)=>total*60+n,0);
 }else{const iso=/^PT(?:(\d{1,3})H)?(?:(\d{1,3})M)?(?:(\d{1,3})S)?$/i.exec(text);if(iso&&(iso[1]||iso[2]||iso[3]))seconds=Number(iso[1]||0)*3600+Number(iso[2]||0)*60+Number(iso[3]||0);}
 return Number.isSafeInteger(seconds)&&seconds>0&&seconds<=604800?seconds:null;
}
export function observedEpisodeMetadata(raw={},base=''){
 const result={};const poster=resolveSafeUrl(raw.poster||raw.thumbnail||raw.image||raw.still_path||'',base,{allowHttp:false});
 if(poster&&poster.length<=4096)result.poster=poster;
 let seconds=Number(raw.duration_seconds);
 if(!Number.isSafeInteger(seconds)||seconds<=0)seconds=observedDurationSeconds(raw.duration||'');
 if(!seconds&&Number.isFinite(Number(raw.runtime_minutes))&&Number(raw.runtime_minutes)>0)seconds=Math.round(Number(raw.runtime_minutes)*60);
 if(Number.isSafeInteger(seconds)&&seconds>0&&seconds<=604800)result.duration_seconds=seconds;
 return result;
}
