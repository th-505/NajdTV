import { createHash, randomUUID } from 'node:crypto';
import { assertSafeScraperUrl, fetchSafeResponse } from './scrapers/shared/http.mjs';

// Reviewed television identities. Feed titles and country membership alone
// cannot establish ownership, programme category or religious affiliation.
const CHANNELS = {
  movies: ['Aflam.sa', 'MoviesAction.sa', 'MoviesThriller.sa', 'RotanaCinemaKSA.sa', 'RotanaClassic.sa', 'OSNMoviesAction.ae'],
  series: ['BabAlHara.sa', 'Maraya.sa', 'RotanaDrama.sa'],
  news: ['AlArabiyaEnglish.sa', 'AlEkhbariya.sa', 'AlHadath.sa', 'AsharqNews.sa', 'AlMashhad.ae', 'KTVNews.kw', 'OmanTVMubashir.om'],
  kids: ['AtfalMawahebTV.sa', 'MajidKidsTV.ae'],
  religious: ['AlQuranAlKareemTV.sa', 'AlSunnahAlNabawiyahTV.sa', 'QatarTVTheHolyQuran.qa'],
};
const categoryByChannel = new Map(Object.entries(CHANNELS).flatMap(([category, ids]) =>
  ids.map(id => [id.toLowerCase(), category])));
const countries = [['ae', 'الإمارات'], ['sa', 'السعودية'], ['kw', 'الكويت'],
  ['qa', 'قطر'], ['bh', 'البحرين'], ['om', 'عُمان']];
export const LIVE_GROUPS = Object.freeze([
  ...countries.map(([id, title]) => [id, title, 'countries/' + id]),
  ['movies', 'الأفلام', 'categories/movies'], ['series', 'المسلسلات', 'categories/series'],
  ['news', 'الأخبار', 'categories/news'], ['kids', 'الأطفال', 'categories/kids'],
  ['religious', 'القنوات الإسلامية السنية', 'categories/religious'],
].map(([id, title, path]) => Object.freeze({ id, title, url: `https://iptv-org.github.io/iptv/${path}.m3u` })));

function gulfChannels(text, group) {
  return parseLivePlaylist(text, identity => {
    const id = identity.split('@', 1)[0].toLowerCase();
    const category = categoryByChannel.get(id);
    return Boolean(category && (group === category || id.endsWith('.' + group)));
  });
}
const TTL = 12 * 3600000, STALE = 24 * 3600000, RETRY = 60000;
function publicUrl(raw) {
  if (typeof raw !== 'string' || raw.length > 4096 || /[\x00-\x20\\]/.test(raw)) return null;
  try { const url = assertSafeScraperUrl(raw, { allowHttp: false });
    return url.port || url.hash || !/^[a-z0-9-]+(?:\.[a-z0-9-]+)+$/i.test(url.hostname) || /^(?:\d+\.){3}\d+$/.test(url.hostname) ? null : url.href; } catch { return null; }
}
function mediaType(url) {
  const path = new URL(url).pathname.toLowerCase();
  return path.endsWith('.mpd') ? 'application/dash+xml' : path.endsWith('.mp4') ? 'video/mp4' :
    path.endsWith('.m3u8') ? 'application/vnd.apple.mpegurl' : /\.(?:ts|m2ts)$/.test(path) ? 'video/mp2t' :
    path.endsWith('.webm') ? 'video/webm' : path.endsWith('.mkv') ? 'video/x-matroska' : null;
}
export function parseLivePlaylist(text, accepts = () => true) {
  if (!/^\uFEFF?#EXTM3U(?:\s|$)/.test(text)) throw Error('LIVE_INVALID_PLAYLIST');
  const channels = new Map(); let pending = null, skipped = 0;
  for (const line of text.split(/\r?\n/)) {
    const value = line.trim();
    if (value.length > 8192) { pending = null; skipped++; continue; }
    if (value.startsWith('#EXTINF:')) {
      const split = value.match(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/);
      const attributes = Object.fromEntries([...value.matchAll(/([\w-]+)="([^"]*)"/g)].map(m => [m[1], m[2]]));
      pending = { title: (split ? value.slice(split.index + 1) : '').trim().slice(0, 256),
        identity: attributes['tvg-id'] || '', poster: publicUrl(attributes['tvg-logo']) || '' };
    } else if (value && !value.startsWith('#')) {
      const row = pending; pending = null;
      const url = publicUrl(value), type = url && mediaType(url);
      if (!row?.title || !type || !accepts(row.identity)) { skipped++; continue; }
      const id = createHash('sha256').update(row.identity || url).digest('hex').slice(0, 24);
      const channel = channels.get(id) || { id, ref: `live:iptv-org:${id}`, title: row.title, poster: row.poster, type: 'live', streams: [] };
      if (channel.streams.length < 5 && !channel.streams.some(s => s.url === url)) channel.streams.push({ url, media_type: type });
      channels.set(id, channel);
      if (channels.size > 20000) throw Error('LIVE_PLAYLIST_TOO_LARGE');
    }
  }
  return { channels: [...channels.values()], skipped };
}
export function createLiveCatalog({ fetchPlaylist = async url => {
  const result = await fetchSafeResponse(url, { allowedHosts: ['iptv-org.github.io'], allowHttp: false,
    timeoutMs: 8000, maxRetries: 0, maxRedirects: 2, maxBytes: 4 * 1024 * 1024 });
  if (!result.ok) throw Error('LIVE_UPSTREAM_UNAVAILABLE');
  return result.html;
}, now = Date.now } = {}) {
  const cache = new Map(), pending = new Map(), retryAt = new Map(), forcedAt = new Map();
  async function load(id, force = false) {
    const group = LIVE_GROUPS.find(row => row.id === id);
    if (!group) throw Error('LIVE_UNKNOWN_GROUP');
    if (force && pending.has(id)) return pending.get(id);
    force = force && (!forcedAt.has(id) || now() - forcedAt.get(id) >= RETRY);
    if (force) forcedAt.set(id, now());
    const old = cache.get(id), age = old ? now() - old.at : Infinity;
    if (age < TTL && !force) return { ...old, stale: false };
    if (now() < (retryAt.get(id) || 0)) {
      if (age < STALE) return { ...old, stale: true };
      throw Error('LIVE_UPSTREAM_UNAVAILABLE');
    }
    if (!pending.has(id)) {
      const work = Promise.resolve().then(() => fetchPlaylist(group.url)).then(text => gulfChannels(text, id))
        .then(result => { const entry = { ...result, at: now() }; cache.set(id, entry); retryAt.delete(id); return { ...entry, stale: false }; })
        .catch(() => { retryAt.set(id, now() + RETRY); if (age < STALE) return { ...old, stale: true }; throw Error('LIVE_UPSTREAM_UNAVAILABLE'); })
        .finally(() => pending.delete(id));
      pending.set(id, work);
    }
    // Existing channels remain usable during refresh, without an upstream wait.
    if (age < STALE && !force) { pending.get(id).catch(() => {}); return { ...old, stale: true }; }
    return pending.get(id);
  }
  return {
    groups: () => LIVE_GROUPS.map(({ id, title }) => ({ id, title })),
    async catalog({ group = 'sa', page = 1, q = '' } = {}) {
      if (!Number.isSafeInteger(page) || page < 1 || page > 400 || typeof q !== 'string' || q.length > 120) throw Error('LIVE_BAD_QUERY');
      const result = await load(group), term = q.trim().normalize('NFKC').toLocaleLowerCase();
      const rows = result.channels.filter(row => !term || row.title.normalize('NFKC').toLocaleLowerCase().includes(term));
      return { status: 'success', data: rows.slice((page - 1) * 60, page * 60).map(({ streams, ...row }) => ({ ...row, ref: `live:iptv-org:${group}:${row.id}` })),
        pagination: { page, has_more: page * 60 < rows.length, total: rows.length },
        stale: result.stale, skipped: result.skipped, updated_at: new Date(result.at).toISOString() };
    },
    async playback(ref, refresh = false) {
      const match = /^live:iptv-org:([a-z]+):([a-f0-9]{24})$/.exec(ref);
      if (!match) throw Error('LIVE_BAD_REFERENCE');
      const result = await load(match[1], refresh), row = result.channels.find(row => row.id === match[2]);
      if (!row) throw Error('LIVE_CHANNEL_NOT_FOUND');
      // Fresh capability per open; no per-user playback state or signed URL cache.
      const expires = new Date(now() + 6 * 3600000).toISOString(); // App registration lease, not an upstream availability claim.
      return { status: 'success', data: { expires_at: expires, title: row.title, poster: row.poster, playback_mode: 'direct',
        playback_session: randomUUID(), media_path: row.streams[0].url, media_type: row.streams[0].media_type,
        media_sources: row.streams.map(stream => ({ ...stream, expires_at: expires, provider: 'IPTV-org', source_ref: ref, playback_mode: 'direct' })) } };
    },
  };
}
