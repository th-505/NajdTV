/** Direct video only: no transcoding, ad SDK, iframe or paid codec service. */
export const VIDEO_EXTENSIONS = Object.freeze(['mp4','m3u8','mpd','webm','mkv','mov','m4v','avi','ts','m2ts','mpeg','mpg','ogv','flv']);
export const NATIVE_CONTAINERS = Object.freeze(['mp4','hls','dash','webm','matroska','quicktime','avi','mpeg-ts','mpeg','ogg','flv']);
export function mediaFormatFromUrl(value){try{const p=new URL(value).pathname.toLowerCase();const ext=p.match(/\.([a-z0-9]+)$/)?.[1];return VIDEO_EXTENSIONS.includes(ext)?ext:p.includes('/hls/')||p.endsWith('/master.txt')?'m3u8':null;}catch{return null;}}
export function containerForFormat(format){return {mp4:'mp4',m4v:'mp4',m3u8:'hls',mpd:'dash',webm:'webm',mkv:'matroska',mov:'quicktime',avi:'avi',ts:'mpeg-ts',m2ts:'mpeg-ts',mpeg:'mpeg',mpg:'mpeg',ogv:'ogg',flv:'flv'}[format]||null;}
export function observedContainer(bytes){
 if(!bytes||bytes.length<4)return null;
 const b=Buffer.from(bytes),text=b.subarray(0,4096).toString('utf8').trimStart();
 if(b.length>=12&&b.subarray(4,8).toString('ascii')==='ftyp')return b.subarray(8,12).toString('ascii').startsWith('qt')?'quicktime':'mp4';
 if(text.startsWith('#EXTM3U'))return 'hls';
 if(/^(?:<\?xml[^>]*>\s*)?<MPD(?:\s|>)/.test(text))return 'dash';
 if(b.readUInt32BE(0)===0x1a45dfa3){if(text.includes('webm'))return 'webm';if(text.includes('matroska'))return 'matroska';return null;}
 if(b.subarray(0,4).toString('ascii')==='RIFF'&&b.subarray(8,12).toString('ascii')==='AVI ')return 'avi';
 if((b[0]===0x47&&b.length>376&&b[188]===0x47&&b[376]===0x47)||(b.length>388&&b[4]===0x47&&b[196]===0x47&&b[388]===0x47))return 'mpeg-ts';
 if(b.subarray(0,4).toString('ascii')==='OggS')return 'ogg';
 if(b.subarray(0,3).toString('ascii')==='FLV')return 'flv';
 if(b[0]===0&&b[1]===0&&b[2]===1&&[0xb3,0xba].includes(b[3]))return 'mpeg';
 return null;
}
