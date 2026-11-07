// Pure shared title normalization, no provider or mutable state.
export function identityTitle(value) {
  return String(value || '').normalize('NFKC').toLocaleLowerCase('ar')
    .replace(/[٠-٩]/g, c => String(c.charCodeAt(0) - 1632))
    .replace(/[ıİ]/g,'i').replace(/\u0307/g,'')
    .replace(/^(?:(?:مشاهدة|تحميل|فيلم|مسلسل|انمي|أنمي|anime)\s+)+/g, '')
    .replace(/(?:الموسم|موسم)\s*(?:الأول|الاول|الثاني|الثالث|الرابع|الخامس|السادس|السابع|الثامن|التاسع|العاشر)(?=$|\s)/g,'')
    .replace(/(?:^|\s)ج\s*\d+(?=$|\s)/g,' ')
    .replace(/(?:الموسم|موسم|season)\s*\d+|(?:الحلقة|الحلقه|حلقة|حلقه|episode)\s*\d+/gi, '')
    .replace(/[\u064B-\u065F\u0670]/g, '')
    .replace(/\b(?:19|20)\d{2}\b/g, '')
    .replace(/\s+(?:مترجم|مدبلج|كامل|اون لاين|أون لاين|HD|WEB-DL|BluRay).*$/i, '')
    .replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
}
