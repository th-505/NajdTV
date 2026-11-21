import {createHmac, randomBytes, timingSafeEqual} from 'node:crypto';
import {assertSafeScraperUrl} from './scrapers/shared/http.mjs';

const ttl = 365 * 86400;
const namePattern = /^[a-z0-9][a-z0-9-]{0,79}\.(m3u8|mp4)$/;

export function createQuickWatch({
  entries = process.env.NAJD_QUICK_WATCH_MEDIA,
  key = process.env.NAJD_QUICK_WATCH_KEY,
  origin = 'https://najdtv.onrender.com',
  now = () => Math.floor(Date.now() / 1000),
} = {}) {
  const media = new Map();
  if (entries && /^[a-f0-9]{64}$/i.test(key || '')) {
    const rows = JSON.parse(entries);
    if (!Array.isArray(rows) || rows.length > 500) throw Error('INVALID_QUICK_WATCH_CATALOG');
    for (const row of rows) {
      const target = assertSafeScraperUrl(row.url, {allowHttp: false});
      if (!namePattern.test(row.name) || media.has(row.name) ||
          typeof row.ref !== 'string' || !row.ref || row.ref.length > 4096 ||
          !target.pathname.endsWith(row.name.slice(row.name.lastIndexOf('.'))) ||
          target.search || target.hash) throw Error('INVALID_QUICK_WATCH_ENTRY');
      media.set(row.name, {...row, url: target.href});
    }
  }
  const sign = (prefix, row) => createHmac('sha256', Buffer.from(key, 'hex'))
    .update(JSON.stringify([prefix, row.name, row.ref, row.season, row.episode, row.url]))
    .digest();
  return {
    ready: media.size > 0,
    issue(input) {
      if (!input || typeof input.ref !== 'string') return null;
      const row = [...media.values()].find(candidate =>
        candidate.ref === input.ref && (candidate.season ?? 0) === (input.season ?? 0) &&
        (candidate.episode ?? 0) === (input.episode ?? 0));
      if (!row) return null;
      const prefix = (now() + ttl).toString(36) + '_' + randomBytes(18).toString('hex');
      return origin + '/watch/' + prefix + '_' + sign(prefix, row).toString('hex') + '/' + row.name;
    },
    resolve(token, name) {
      const match = /^([0-9a-z]{1,10})_([a-f0-9]{36})_([a-f0-9]{64})$/.exec(token);
      const row = media.get(name);
      if (!row || !match || parseInt(match[1], 36) <= now()) return null;
      const signature = sign(match[1] + '_' + match[2], row);
      return timingSafeEqual(signature, Buffer.from(match[3], 'hex')) ? row.url : null;
    },
  };
}

export async function authenticateQuickWatch(header, fetcher = fetch) {
  const token = /^Bearer ([^\s]{1,8192})$/i.exec(header || '')?.[1];
  const url = process.env.SUPABASE_URL || '';
  const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!token || !/^https:\/\/[a-z0-9]+\.supabase\.co\/?$/.test(url) || !key) return false;
  const response = await fetcher(new URL('/auth/v1/user', url), {
    redirect: 'error', signal: AbortSignal.timeout(5000),
    headers: {apikey: key, authorization: 'Bearer ' + token},
  });
  if (!response.ok) {
    await response.body?.cancel();
    return false;
  }
  const user = await response.json();
  return Boolean(user?.id && user.email_confirmed_at && user.is_anonymous === false);
}
