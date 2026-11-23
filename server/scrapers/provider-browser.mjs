import { createHash } from 'node:crypto';
import {assertSafeScraperUrl} from './shared/http.mjs';
import {getProviderConfig,effectiveProviderDomains} from './shared/provider-config.mjs';
import {runInBrowserLane} from '../browser/traffic.mjs';
import {classifyNetworkError} from './shared/errors.mjs';
import { getProvider, listIndependentProviders } from '../browser/registry.mjs';
import { createConcurrencyQueue } from './shared/concurrency.mjs';

// This route never mutates the canonical discovery or preferred-source state.
export function createProviderBrowser({ lookup = getProvider, providers = listIndependentProviders,
  queue = createConcurrencyQueue({ concurrency: 4, maxQueued: 40 }), now=Date.now, catalogTtlMs=120000 } = {}) {
  const successful=new Map(), pending=new Map();let cachedBytes=0;
  const brstejBlocks = new Map();
  const blockTtlMs = 30_000;
  const maxBlockedPages = 64;
  function drop(key){const old=successful.get(key);if(old)cachedBytes-=old.bytes;successful.delete(key);}

  let brstejCircuit;
  function circuitFor(config, domain) {
    const revisionKey = JSON.stringify([config?.revision || 0, domain]);
    if (brstejCircuit?.key !== revisionKey) {
      brstejCircuit = {key: revisionKey, failures: 0, firstFailure: 0, openUntil: 0, probing: false};
    }
    return brstejCircuit;
  }

  async function withBrstejCircuit(circuit, fetchResult) {
    const remaining = circuit.openUntil - now();
    if (remaining > 0 || circuit.probing) {
      throw Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE'), {
        code: 'ACCESS_BLOCKED', circuitOpen: true,
        retryAfterSeconds: Math.max(1, Math.ceil(remaining / 1000)),
      });
    }
    const probe = circuit.openUntil > 0;
    if (probe) circuit.probing = true;
    try {
      const result = await fetchResult();
      if (probe || !circuit.openUntil) {
        circuit.failures = 0;
        circuit.openUntil = 0;
      }
      return result;
    } catch (error) {
      if (error?.code === 'ACCESS_BLOCKED') {
        if (!circuit.failures || now() - circuit.firstFailure >= blockTtlMs) {
          circuit.firstFailure = now();
          circuit.failures = 0;
        }
        if (probe || (++circuit.failures >= 3 && !circuit.openUntil)) {
          circuit.openUntil = now() + blockTtlMs;
        }
      } else if (probe || !circuit.openUntil) {
        circuit.failures = 0;
        circuit.openUntil = 0;
      }
      throw error;
    } finally {
      if (probe) circuit.probing = false;
    }
  }

  function blockedError(key) {
    const until = brstejBlocks.get(key);
    if (until === undefined) return;
    const remaining = until - now();
    if (remaining <= 0) {
      brstejBlocks.delete(key);
      return;
    }
    return Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE'), {
      code: 'ACCESS_BLOCKED', catalogCacheHit: true,
      retryAfterSeconds: Math.ceil(remaining / 1000),
    });
  }

  function rememberBlock(key, error) {
    if (error?.code === 'ACCESS_BLOCKED' && !error.circuitOpen) {
      if (brstejBlocks.size >= maxBlockedPages) {
        brstejBlocks.delete(brstejBlocks.keys().next().value);
      }
      brstejBlocks.set(key, now() + blockTtlMs);
    }
    throw error;
  }

  function entry(id) {
    const provider = lookup(id);
    if (!provider || provider.meta.mirrorOf || provider.meta.enabled === false) throw Error('BROWSER_PROVIDER_UNAVAILABLE');
    return provider;
  }
  function categories(id) {
    const provider = entry(id);
    const config = Object.values(provider.module).find(value => value && typeof value === 'object'
      && value.categories && typeof value.categories === 'object');
    const labels = { latest: 'الأحدث', home: 'الرئيسية', all: 'الكل', movies: 'الأفلام', movie: 'الأفلام',
      movies_all: 'كل الأفلام', series: 'المسلسلات', tv: 'المسلسلات', anime: 'الأنمي', arabic: 'عربي',
      movies_arabic: 'أفلام عربية', movies_foreign: 'أفلام أجنبية', series_arabic: 'مسلسلات عربية',
      series_foreign: 'مسلسلات أجنبية', series_turkish: 'مسلسلات تركية', today: 'اليوم', live: 'بث مباشر' };
    return Object.keys(config?.categories || {}).map(key => ({ id: key,
      label: config?.categoryLabels?.[key] || labels[key] || key.replace(/[-_]/g, ' ') }));
  }
  return {
    sources: () => runInBrowserLane(()=>providers().filter(meta => meta.enabled !== false && meta.capabilities?.catalog
      && typeof lookup(meta.id)?.module.scrapeCatalog === 'function')
      .map(meta => ({ id: meta.id, name: meta.name, domain: new URL(meta.domains[0]).hostname,
        content_type:meta.capabilities?.live===true && meta.capabilities?.episodes!==true?'live':'vod',categories: categories(meta.id) }))),
    async search(id, query, page = 1) { return runInBrowserLane(async () => {
      const provider = entry(id);
      if (id === 'brstej') query = query.trim();
      if (!provider.module.scrapeSearch) throw Error('BROWSER_PROVIDER_UNAVAILABLE');
      if (query.length < 2 || query.length > 120 || !Number.isSafeInteger(page) || page < 1 || page > 500) {
        throw Error('BROWSER_BAD_QUERY');
      }
      const fetchSearch = async () => {
        const items = await provider.module.scrapeSearch(query, page, {
          strict: true, allowHttp: false, timeoutMs: 6500, maxRetries: 0,
        });
        if (items?._meta?.errorCode && items._meta.errorCode !== 'EMPTY_RESULT') {
          throw Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE'), {code: items._meta.errorCode});
        }
        return items;
      };
      if (id !== 'brstej') return fetchSearch();
      const config = getProviderConfig(id);
      const digest = createHash('sha256').update(query).digest('hex');
      const key = JSON.stringify(['search', id, digest, page, config?.revision || 0,
        config?.primary_domain || provider.meta.domains[0]]);
      const error = blockedError(key);
      if (error) throw error;
      if (pending.has(key)) return pending.get(key);
      const circuit = circuitFor(config, config?.primary_domain || provider.meta.domains[0]);
      const work = withBrstejCircuit(circuit, fetchSearch).catch(error => rememberBlock(key, error))
        .finally(() => pending.delete(key));
      pending.set(key, work);
      return work;
    }); },
    async catalog(id, category, page = 1) { return runInBrowserLane(async()=>{
      const provider = entry(id);
      if (typeof provider.module.scrapeCatalog !== 'function') throw Error('BROWSER_CATALOG_UNSUPPORTED');
      if (!Number.isInteger(page) || page < 1 || page > 500) throw Error('BROWSER_BAD_PAGE');
      const allowed = categories(id);
      const selected = category || allowed[0]?.id;
      if (selected && !allowed.some(item => item.id === selected)) throw Error('BROWSER_BAD_CATEGORY');
      const config=getProviderConfig(id);
      const cacheKey=number=>JSON.stringify([id,selected,number,config?.revision||0,config?.primary_domain||provider.meta.domains[0]]);
      const key=cacheKey(page);
      const cached=successful.get(key);
      if(cached&&cached.expires>now())return structuredClone(cached.data);
      if(cached)drop(key);
      if (id === 'brstej') {
        const error = blockedError(key);
        if (error) throw error;
      }
      if(pending.has(key))return structuredClone(await pending.get(key));
      let observedNextUrl=null;
      async function fetchPage(){
      const previous=successful.get(cacheKey(page-1));
      const nextUrl=previous?.expires>now()&&previous.data.pagination.next_page===page?previous.nextUrl:null;
      let result;
      try{result=await queue.run(()=>runInBrowserLane(()=>provider.module.scrapeCatalog(selected,page,{strict:true,allowHttp:false,timeoutMs:8000,maxRetries:0,...(nextUrl?{searchPageUrl:nextUrl}:{})})));}
      catch(error){const failure=new Error('BROWSER_SOURCE_UNAVAILABLE',{cause:error});failure.code=error?.code||classifyNetworkError(error).code;throw failure;}
      if(result?._meta?.errorCode&&result._meta.errorCode!=='EMPTY_RESULT'){
        const failure=new Error('BROWSER_SOURCE_UNAVAILABLE');failure.code=result._meta.errorCode;throw failure;
      }
      const items = Array.isArray(result) ? result : result?.items;
      if (!Array.isArray(items)) throw Error('BROWSER_INVALID_RESPONSE');
      const meta = result?._meta || {};
      const nextPage = Number(meta.next_page);
      const observedNext = Number.isInteger(nextPage) && nextPage > page;
      if(observedNext&&typeof meta.next_url==='string'&&meta.next_url.length<=4096){
        try{observedNextUrl=assertSafeScraperUrl(meta.next_url,{allowHttp:false,allowedHosts:effectiveProviderDomains(id,provider.meta.domains.map(domain=>new URL(domain).hostname))}).href;}catch{}
      }
      const explicitPagination = Object.hasOwn(meta, 'next_page') || Object.hasOwn(meta, 'has_more');
      return { status: 'success', provider: id, category: selected || null,
        items: items.filter(item => item?.ref && item?.title).map(item => ({
          id:item.id||item.ref,ref:item.ref,title:item.title,poster:item.poster||item.image||'',
          type:item.type||'series',year:item.year||null,
          rating:Number.isFinite(Number(item.rating))?Math.max(0,Math.min(10,Number(item.rating))):0,
          genres:Array.isArray(item.genres)?item.genres:[],edition:item.edition||'',
          audio_language:item.audio_language||'',imdb_id:item.imdb_id||'',
          identity_verified:item.identity_verified===true,work_identity_verified:item.work_identity_verified===true,
          source: id, selected_source: id, source_refs: { [id]: item.ref } })),
        pagination: { page, next_page: observedNext ? nextPage : null,
          has_more: explicitPagination ? observedNext || meta.has_more === true : items.length > 0,
          basis: explicitPagination ? 'observed-source-pagination' : 'adapter-page-probe' } };
      }
      const circuit = id === 'brstej' ? circuitFor(config, config?.primary_domain || provider.meta.domains[0]) : null;
      const work=(circuit ? withBrstejCircuit(circuit, fetchPage) : fetchPage()).then(data=>{
        if(data.items.length){
          const bytes=Buffer.byteLength(JSON.stringify(data));
          if(bytes<=256*1024){
            drop(key);
            while(successful.size>=80||cachedBytes+bytes>8*1024*1024){drop(successful.keys().next().value);}
            successful.set(key,{data:structuredClone(data),nextUrl:observedNextUrl,bytes,expires:now()+Math.max(0,Math.min(120000,catalogTtlMs))});cachedBytes+=bytes;
          }
        }
        return data;
      }).catch(error => {
        if (id === 'brstej') return rememberBlock(key, error);
        throw error;
      }).finally(()=>pending.delete(key));
      pending.set(key,work);
      return structuredClone(await work);
    });},
  };
}
