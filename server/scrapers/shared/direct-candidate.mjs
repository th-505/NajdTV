import {mediaFormatFromUrl} from '../../../shared/media-container.mjs';
export function directCandidate(server) {
  if (server?.kind === 'embed' || server?.type === 'embed' || server?.streamType === 'embed') return false;
  try {
    const u = new URL(server?.url || '');
    return u.protocol === 'https:' && Boolean(mediaFormatFromUrl(u.href));
  } catch { return false; }
}
