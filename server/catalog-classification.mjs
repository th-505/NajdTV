// Descriptive evidence only: no source episode numbering or playback claims.
export const isAdultCatalogItem = item => item?.adult === true || item?.adult === 'true';
export function isJapaneseAnime(item = {}) {
 const ids = [...(Array.isArray(item.genre_ids) ? item.genre_ids : []),
  ...(Array.isArray(item.genres) ? item.genres.map(row => row?.id) : [])].map(Number);
 return item.original_language === 'ja' && ids.includes(16);
}
export function catalogLabels(item = {}) {
 return [...(isJapaneseAnime(item) ? ['أنمي'] : []),
  ...(item.original_language === 'tr' ? ['تركي'] : [])];
}
