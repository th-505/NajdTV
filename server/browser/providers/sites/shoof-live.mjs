import * as cheerio from 'cheerio';
import { performance } from 'node:perf_hooks';
import { effectiveProviderDomains } from '../../../scrapers/shared/provider-config.mjs';
import { fetchProviderHtml, resolveSafeUrl } from '../../../scrapers/shared/http.mjs';
import { attachResultMeta, ScraperError } from '../../../scrapers/shared/errors.mjs';
import { extractEpisodeNumber, extractSeasonNumber, normalizeCatalogItem, normalizeDetailsResult,
  normalizeEpisodeList, normalizeServerList } from '../../../scrapers/shared/normalize.mjs';
import { extractRawStreamsFromText } from '../../../scrapers/stream-unwrapper.mjs';

const ORIGIN = 'https://m1.shooflive.buzz';
const ID = 'shoof-live';
const domains = [ORIGIN, 'https://shooflive.watch'];
function configuredHosts(key, defaults) {
  const extra = String(process.env[key] || '').split(',').map(value => value.trim().toLowerCase())
    .filter(value => /^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/.test(value));
  return [...new Set([...defaults, ...extra])];
}
const playerHosts = () => configuredHosts('SHOOF_LIVE_PLAYER_HOSTS', ['shooof.online']);
const embedHosts = () => configuredHosts('SHOOF_LIVE_EMBED_HOSTS', ['anafast.cyou', 'mp4plus.cyou', 'vidspeed.org', 'vidspeeds.org', 'cdnplus.org', 'vk.com', 'voe.sx']);
export const PROVIDER_META = Object.freeze({
  id:'shoof-live', name:'شوف لايف', code:'SHFL', domains,
  mirrorOf:null, resolveOnDetails:true,
  capabilities:{catalog:true,search:true,details:true,episodes:true,servers:true,resolve:true,live:false},
  searchSpec:{method:'GET',pathTemplate:'/?s={query}',queryParam:'s',pagination:true},
});
const workHosts = () => effectiveProviderDomains(ID, domains.map(url => new URL(url).hostname));
const context = baseUrl => ({providerId:ID, baseUrl, allowHttp:false});
const reference = url => ID + ':' + Buffer.from(url).toString('base64url');
const clean = value => String(value || '').replace(/\s+/g, ' ').trim();
function safe(value, base, allowedHosts) {
  try {
    const url = new URL(value || '', base);
    if (!value || url.protocol !== 'https:') return null;
    return resolveSafeUrl(url.href, base, {allowHttp:false, allowedHosts}) || null;
  } catch { return null; }
}
const pathOf = value => new URL(value).pathname;
const isWork = url => /^\/(movies|series|episode)\/[^/]+\/?$/.test(pathOf(url));
const diagnostic = new Map();
export function getShoofDiagnostics() {
  return Array.from(diagnostic, ([server, record]) => ({server, ...record,
    successRate:record.successes / record.attempts,
    averageMs:Math.round(record.totalMs / record.attempts)}));
}
function record(host, start, reason) {
  const entry = diagnostic.get(host) || {attempts:0,successes:0,totalMs:0,lastFailure:null};
  entry.attempts++;
  entry.totalMs += performance.now() - start;
  if (reason) entry.lastFailure = reason;
  else entry.successes++;
  diagnostic.set(host, entry);
}
export function decodeProviderRef(input) {
  const value = String(input || '');
  const raw = value.startsWith(ID + ':') ? Buffer.from(value.slice(ID.length + 1), 'base64url').toString() : value;
  const url = safe(raw, ORIGIN, workHosts());
  if (!url || !isWork(url)) throw new ScraperError('INVALID_INPUT', 'SHOOF_INVALID_REFERENCE', {providerId:ID});
  return url;
}
async function page(url, options, allowedHosts, referer) {
  const result = await fetchProviderHtml(url, {
    ...options, searchPageUrl:undefined, providerId:ID, allowHttp:false, allowedHosts, referer,
    timeoutMs:Math.min(6000, options.timeoutMs || 6000), maxRetries:0, maxBytes:2*1024*1024,
  });
  if (!result.ok) throw new ScraperError('UPSTREAM_UNAVAILABLE', 'SHOOF_UPSTREAM_HTTP', {providerId:ID,status:result.status});
  return result;
}
function poster(img, base) {
  return [img.attr('data-src'), img.attr('src')].find(url => url &&
    !/(?:placeholder\.gif|^data:)/i.test(url) && safe(url, base)) || '';
}
export async function scrapeSearch(query, n=1, options={}) {
  const q = clean(query);
  if (q.length < 2 || q.length > 120) return [];
  if (!Number.isSafeInteger(n) || n < 1) throw new ScraperError('INVALID_INPUT', 'SHOOF_INVALID_PAGE');
  const url = new URL(n === 1 ? '/' : '/search/' + encodeURIComponent(q) + '/', ORIGIN);
  url.searchParams.set(n === 1 ? 's' : 'sp', n === 1 ? q : String(n));
  const result = await page(url.href, options, workHosts());
  const $ = cheerio.load(result.html);
  const root = $('#shooflive-smart-search');
  if (!root.length) throw new ScraperError('STRUCTURE_CHANGED', 'SHOOF_SEARCH_STRUCTURE_CHANGED');
  const items = new Map();
  root.find('.slv2-grid a.slv2-card').each((_, node) => {
    const card = $(node);
    const target = safe(card.attr('href'), result.url, workHosts());
    const title = clean(card.find('.slv2-name').text() || card.attr('title'));
    if (!target || !isWork(target) || !title || pathOf(target).startsWith('/episode/')) return;
    const item = normalizeCatalogItem({url:target,ref:reference(target),title,
      type:pathOf(target).startsWith('/series/') ? 'series' : 'movie',
      poster:poster(card.find('.slv2-poster img').first(), result.url)}, context(result.url));
    if (item) items.set(target, {...item,badge:clean(card.find('.slv2-badge').text())});
  });
  const next = root.find('.slv2-pages a[href]').toArray().map(node => {
    const target = safe($(node).attr('href'), result.url, workHosts());
    return target && pathOf(target).toLowerCase() === ('/search/' + encodeURIComponent(q) + '/').toLowerCase() ?
      Number(new URL(target).searchParams.get('sp')) : null;
  }).find(value => value === n + 1);
  return attachResultMeta([...items.values()], {ok:true,providerId:ID,next_page:next || null});
}
export async function scrapeDetails(ref, options={}) {
  const result = await page(decodeProviderRef(ref), options, workHosts());
  const $ = cheerio.load(result.html);
  const title = clean($('.singleSeries .info h1, h1').first().text());
  if (!title) throw new ScraperError('STRUCTURE_CHANGED', 'SHOOF_DETAILS_STRUCTURE_CHANGED');
  const series = pathOf(result.url).startsWith('/series/');
  const episodes = [];
  if (series) $('article.postEp').each((_, node) => {
    const card = $(node);
    const target = safe(card.find('a[href*="/episode/"]').first().attr('href'), result.url, workHosts());
    if (!target || !isWork(target)) return;
    const label = clean(card.find('.title').first().text());
    const number = extractEpisodeNumber('الحلقة ' + (clean(card.find('.episodeNum').first().text()).match(/[0-9٠-٩۰-۹]+/u)?.[0] || '')) ??
      extractEpisodeNumber(label, target);
    episodes.push({url:target,ref:reference(target),title:label,number,season:extractSeasonNumber(label),
      watch_available:!(/سيتم\s+اضافة\s+الحلقة|سيتم\s+إضافة\s+الحلقة/u.test(card.text())),
      poster:poster(card.find('img').first(), result.url)});
  });
  const ctx = context(result.url);
  return normalizeDetailsResult({sourceUrl:result.url,ref:reference(result.url),title,
    poster:poster($('.singleSeries .cover img').first(), result.url),
    type:series || pathOf(result.url).startsWith('/episode/') ? 'series' : 'movie',
    overview:clean($('meta[property="og:description"]').attr('content')),
    episodes:normalizeEpisodeList(episodes, ctx)}, ctx);
}
export async function scrapeEpisodes(ref, options={}) {
  return (await scrapeDetails(ref, options)).episodes;
}
function playerLinks(result) {
  const $ = cheerio.load(result.html);
  const links = $('.singleSeries iframe[src], iframe[src*="/albaplayer/"], a[href*="/albaplayer/"]').toArray();
  return [...new Set(links.map(node =>
    safe($(node).attr('src') || $(node).attr('href'), result.url, playerHosts()))
    .filter(url => url && /^\/albaplayer\/[^/]+\/?$/.test(pathOf(url))))];
}

async function walk(entries, visit) {
  let next = 0;
  const results = [];
  async function worker() {
    while (next < entries.length) {
      const current = next++;
      results[current] = await visit(entries[current]);
    }
  }
  await Promise.all(Array.from({length:Math.min(3, entries.length)}, worker));
  return results.flat().filter(Boolean);
}

function publicFailure(error) {
  const known = ['ACCESS_BLOCKED','UPSTREAM_UNAVAILABLE','UPSTREAM_TIMEOUT','UNSAFE_URL','RATE_LIMITED'];
  return known.includes(error?.code) ? error.code : 'UPSTREAM_ERROR';
}

async function observedServers(ref, options) {
  const target = decodeProviderRef(ref);
  if (pathOf(target).startsWith('/series/')) return [];
  let work = await page(target, options, workHosts());
  let players = playerLinks(work);
  if (!players.length) {
    const $ = cheerio.load(work.html);
    const workPath = pathOf(work.url).replace(/\/$/, '');
    if (workPath.startsWith('/episode/') || workPath.startsWith('/movies/')) {
      const serverPath = workPath + '/servers/';
      const advertised = $('a[href*="/servers/"]').toArray().map(node =>
        safe($(node).attr('href'), work.url, workHosts())).find(url => url && pathOf(url) === serverPath);
      const serverPage = new URL(serverPath, work.url);
      work = await page(advertised || serverPage.href, options, workHosts(), work.url);
      players = playerLinks(work);
    }
  }
  const servers = await walk(players, async player => {
    const started = performance.now();
    let initial;
    try { initial = await page(player, options, playerHosts(), work.url); }
    catch (error) { record(new URL(player).hostname, started, publicFailure(error)); return []; }
    const $ = cheerio.load(initial.html);
    const menu = new Map();
    $('ul.aplr-menu li a.aplr-link[href]').each((_, node) => {
      const anchor = $(node);
      const url = safe(anchor.attr('href'), initial.url, playerHosts());
      if (!url || !/^\/albaplayer\/[^/]+\/?$/.test(pathOf(url))) return;
      if (!/^\d+$/.test(new URL(url).searchParams.get('serv') || '')) return;
      menu.set(url, {url, name:clean(anchor.text()), active:anchor.hasClass('active')});
    });
    const choices = menu.size ? [...menu.values()] : [{url:initial.url, name:'شوف لايف', active:true}];
    return walk(choices, async choice => {
      const started = performance.now();
      try {
        const selected = choice.active ? initial : await page(choice.url, options, playerHosts(), initial.url);
        const html = cheerio.load(selected.html);
        const embed = safe(html('.aplr-player-content iframe#iframe[src], .aplr-player-content iframe[src]').first().attr('src'),
          selected.url, embedHosts());
        if (!embed) {
          record(new URL(selected.url).hostname, started, 'EMBED_UNAVAILABLE');
          return [];
        }
        return [{url:embed, label:choice.name, referer:selected.url}];
      } catch (error) { record(new URL(choice.url).hostname, started, publicFailure(error)); return []; }
    });
  });
  return servers;
}

export async function scrapeServers(ref, options={}) {
  const servers = await observedServers(ref, options);
  return normalizeServerList(servers, {...context(ORIGIN),providerName:'شوف لايف',codePrefix:'SHFL'});
}

function observedExpiry(url) {
  const query = new URL(url).searchParams;
  const issued = query.get('s') || '';
  const lifetime = query.get('e') || '';
  if (!query.get('t') || !/^\d{10}$/.test(issued) || !/^\d{1,6}$/.test(lifetime) || Number(lifetime) < 1) return null;
  return (Number(issued) + Number(lifetime)) * 1000;
}

export async function resolveStream(ref, options={}) {
  const observed = await observedServers(ref, options);
  const resolved = await walk(observed, async server => {
    const host = new URL(server.url).hostname;
    const started = performance.now();
    try {
      const embed = await page(server.url, options, embedHosts(), server.referer);
      const candidates = extractRawStreamsFromText(embed.html, embed.url)
        .filter(stream => safe(stream.url, embed.url) && ['m3u8','mp4'].includes(stream.streamType))
        .map(stream => ({...stream,label:server.label,expiresAt:observedExpiry(stream.url)}));
      const streams = candidates.filter(stream => stream.expiresAt === null || stream.expiresAt > Date.now());
      record(host, started, streams.length ? null : candidates.length ? 'MEDIA_EXPIRED' : 'DIRECT_MEDIA_NOT_OBSERVED');
      return streams;
    } catch (error) { record(host, started, publicFailure(error)); return []; }
  });
  const expiryByUrl = new Map(resolved.map(stream => [new URL(stream.url).href, stream.expiresAt]));
  const servers = normalizeServerList(resolved, {...context(ORIGIN),providerName:'شوف لايف',codePrefix:'SHFL'})
    .map(server => ({...server,expiresAt:expiryByUrl.get(server.url) ?? null}));
  const first = servers[0];
  return attachResultMeta({ok:Boolean(first),providerId:ID,
    url:first?.url || null,streamUrl:first?.url || null,streamType:first?.streamType || null,
    headers:first?.headers || {},servers},
  {ok:Boolean(first),providerId:ID,errorCode:first ? null : 'SERVER_EXTRACTION_FAILED'});
}

export const SHOOF_CONFIG = Object.freeze({
  categories:{latest:'/'},
  categoryLabels:{latest:'الأحدث'},
});

export async function scrapeCatalog(category='latest', n=1, options={}) {
  if (category !== 'latest' || !Number.isSafeInteger(n) || n < 1) {
    throw new ScraperError('INVALID_INPUT', 'SHOOF_INVALID_CATALOG_REQUEST');
  }
  const meta = {ok:true,providerId:ID,next_page:null};
  if (n > 1) return attachResultMeta([], meta);
  const result = await page(ORIGIN + '/', options, workHosts());
  const $ = cheerio.load(result.html);
  const items = new Map();
  $('main .block-post > a[href]').each((_, node) => {
    const card = $(node);
    const url = safe(card.attr('href'), result.url, workHosts());
    if (!url || !isWork(url) || pathOf(url).startsWith('/episode/') || items.has(url)) return;
    const image = card.find('img').first();
    const title = clean(card.find('.title').first().text() || card.attr('title') || image.attr('alt'));
    const item = normalizeCatalogItem({url,ref:reference(url),title,poster:poster(image,result.url),
      type:pathOf(url).startsWith('/series/') ? 'series' : 'movie'}, context(result.url));
    if (item) items.set(url,item);
  });
  if (!items.size) throw new ScraperError('STRUCTURE_CHANGED', 'SHOOF_CATALOG_STRUCTURE_CHANGED');
  return attachResultMeta([...items.values()], meta);
}
