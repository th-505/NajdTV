import {isAdultCatalogItem,isJapaneseAnime,catalogLabels} from './catalog-classification.mjs';
import {collectionRequest} from './catalog-collections.mjs';
export const BROWSE_SECTIONS = Object.freeze({
 movies:[['catalog:movie:all','الكل'],['catalog:movie:en','أجنبي'],['catalog:movie:ar','عربي'],['catalog:movie:hi','هندي'],['catalog:movie:ko','آسيوي'],['catalog:movie:tr','تركي']],
 series:[['catalog:tv:all','الكل'],['catalog:tv:en','أجنبي'],['catalog:tv:ar','عربي'],['catalog:tv:tr','تركي'],['catalog:tv:ko','آسيوي']],
 anime:[['catalog:anime:movie','أفلام أنمي'],['catalog:anime:tv','مسلسلات أنمي']],
 turkish:[['catalog:turkish:tv','مسلسلات تركية'],['catalog:turkish:movie','أفلام تركية']],
});
export function browseRequest(ref,page=1){
 const number=Number(page);if(!Number.isInteger(number)||number<1||number>500)throw Error('INVALID_CATALOG_SECTION');
 const collection=collectionRequest(ref,number);if(collection)return collection;
 const known=Object.values(BROWSE_SECTIONS).flat().some(row=>row[0]===ref);
 if(!known)throw Error('INVALID_CATALOG_SECTION');
 const [,group,value]=ref.split(':');
 const type=group==='movie'||group==='tv'?group:value;
 const language=group==='anime'?'ja':group==='turkish'?'tr':['all','en'].includes(value)?null:value;
 return {path:`/discover/${type}`,type,params:{page:String(number),sort_by:'popularity.desc',
   ...(language?{with_original_language:language}:{}),...(group==='anime'?{with_genres:'16'}:{})}};
}
export async function browseCatalog(runtime,ref,page){
 const request=browseRequest(ref,page);
 const asian = ref === 'catalog:tv:ko' || ref === 'catalog:movie:ko';
 let body;
 if (asian) {
  // Keep the installed-client category ID; its historical suffix is not a language restriction.
  const languages = ['ko', 'ja', 'zh', 'cn', 'th'];
  const pages = [];
  for (let offset = 0; offset < languages.length; offset += 4) {
   pages.push(...await Promise.all(languages.slice(offset, offset + 4).map(language =>
    runtime.catalog(request.path, {...request.params, with_original_language: language}))));
  }
  const rows = pages.flatMap(result => result.results || [])
   .filter(item => languages.includes(item.original_language))
   .sort((a, b) => (Number(b.popularity) || 0) - (Number(a.popularity) || 0));
  const seen = new Set();
  body = {
   results: rows.filter(item => {
    if (seen.has(String(item.id))) return false;
    seen.add(String(item.id));
    return true;
   }),
   page: Number(request.params.page),
   total_pages: Math.min(500, Math.max(...pages.map(result => Number(result.total_pages) || 1))),
  };
 } else {
  body = await runtime.catalog(request.path,request.params);
 }
 const ordinarySeries=ref.startsWith('catalog:tv:')||ref.startsWith('catalog:collection:series-');
 const foreign=ref==='catalog:tv:en'||ref==='catalog:movie:en';
 const data=(body.results || []).filter(item=>!isAdultCatalogItem(item)&&
  !(ordinarySeries&&isJapaneseAnime(item))&&
  (!foreign||(item.original_language&&item.original_language!=='ar'))).map(item=>{
  const id=Number(item.id);if(!Number.isSafeInteger(id)||id<=0)return null;
  const title=item.title||item.name;if(!title)return null;
  return {id:`tmdb:${request.type}:${id}`,ref:`tmdb:${request.type}:${id}`,tmdbId:String(id),title,
    originalTitle:item.original_title||item.original_name||title,type:request.type==='tv'?'series':'movie',mediaType:request.type,
    year:String(item.release_date||item.first_air_date||'').slice(0,4)||null,rating:item.vote_count>0?item.vote_average:null,
    poster:item.poster_path?`https://image.tmdb.org/t/p/w500${item.poster_path}`:'',
    overview:item.overview||'',source:'tmdb',...(catalogLabels(item).length?{genres:catalogLabels(item)}:{}),genre_ids:item.genre_ids||[],original_language:item.original_language||'',category:ref};
 }).filter(Boolean);
 return {status:'success',source:'tmdb',data,has_more:Number(body.page||page)<Number(body.total_pages||1),page:Number(body.page||page)};
}
