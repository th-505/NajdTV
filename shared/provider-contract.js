// Additive wire contract. Legacy aliases/status remain available to installed clients.
export function providerErrorCode(error) {
  if(error instanceof SyntaxError) return 'STRUCTURE_CHANGED';
  const value = String(error?.error_code || error?.code || error?.errorCode || error?.message || error || '');
  if (/EMPTY_RESULT/.test(value)) return 'EMPTY_RESULT';
  if (/ACCESS_BLOCKED|HTTP[_ ]?(403|429)|CHALLENGE|CLOUDFLARE|WAF|LOGIN_REQUIRED|DOMAIN_SUSPENDED|REDIRECT_REQUIRES_REVIEW/.test(value)) return 'ACCESS_BLOCKED';
  if (/TIMEOUT|TIMED_OUT|AbortError|TimeoutError|ETIMEDOUT/i.test(value)) return 'TIMEOUT';
  if (/STRUCTURE_CHANGED|BAD_.*(RESPONSE|JSON|PAYLOAD)|INVALID_JSON|SyntaxError/.test(value)) return 'STRUCTURE_CHANGED';
  // Network failures, safety rejections and missing config are not empty results.
  return value && /^[A-Z][A-Z0-9_]+$/.test(value) ? value : 'UPSTREAM_UNAVAILABLE';
}
const observedNumber = value => value !== null && value !== '' && Number.isSafeInteger(Number(value)) && Number(value) > 0 ? Number(value) : null;
export function sourceItem(raw, source = '', episode = false) {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return raw;
  const ref = raw.ref || raw.link || raw.sourceUrl || raw.url || null;
  const result = { ...raw, source:raw.source || source, ref, title:raw.title || raw.movie_title || raw.name || '',
    edition:raw.edition || raw.source_edition || 'unknown', partial:raw.partial === true,
    next_cursor:raw.next_cursor ?? (raw.next_offset != null ? String(raw.next_offset) : null) };
  if (episode) {
    result.episode_id = raw.episode_id || raw.id || ref;
    result.episode_number = observedNumber(raw.episode_number ?? raw.number ?? raw.num);
    // A legacy default `season` is not proof of an observed season number.
    result.season_number = observedNumber(raw.season_number);
    result.watch_available = result.episode_number !== null && raw.watch_available !== false;
  }
  return result;
}
export function sourceResponse(raw, source = '') {
  if (!raw || typeof raw !== 'object') return raw;
  if (Array.isArray(raw)) {
    const result = raw.map(row => sourceItem(row,source));
    if(raw._meta) Object.defineProperty(result,'_meta',{value:{...raw._meta,error_code:raw._meta.errorCode?providerErrorCode(raw._meta):null},enumerable:false,configurable:true});
    return result;
  }
  const result = sourceItem(raw,source);
  if(Array.isArray(raw.episodes)) result.episodes = raw.episodes.map(row=>sourceItem(row,result.source,true));
  if(Array.isArray(raw.data)) result.data = raw.data.map(row=>sourceItem(row,result.source));
  else if(raw.data && typeof raw.data==='object' && (raw.data.source || raw.data.ref || raw.data.episodes)) result.data=sourceResponse(raw.data,result.source);
  const legacyError=raw.error_code || raw.error || raw.errorCode || (raw.status==='error'?raw.message:null);
  result.error_code=legacyError?providerErrorCode(legacyError):null;
  result.state=raw.state || raw.data?.state || (legacyError?'unavailable':raw.partial?'partial':Array.isArray(raw.data)&&!raw.data.length?'empty':'ready');
  if(result.state==='empty') result.error_code='EMPTY_RESULT';
  return result;
}
export function providerContract(provider, source) {
  const result={...provider};
  for(const name of ['category','search','metadata','details','resolve']) if(typeof provider[name]==='function') result[name]=async(...args)=>{
    try { const value=sourceResponse(await provider[name](...args),source);
      if(value && !Array.isArray(value) && value.ref===null && ['metadata','details','resolve'].includes(name)) value.ref=typeof args[0]==='string'?args[0]:null;
      return value; }
    catch(error) { error.error_code=providerErrorCode(error);error.state='unavailable';throw error; }
  };
  return result;
}

export function parsedCollection(rows, html) {
  if (!Array.isArray(rows) || (!rows.length && !/لا توجد|لا يوجد|لم يتم العثور|لم نجد|No (?:results|posts|items)|nothing found|no-results|not-found|search-no-results/i.test(html || ''))) {
    const error=Error('STRUCTURE_CHANGED');error.code='STRUCTURE_CHANGED';throw error;
  }
  return rows;
}
