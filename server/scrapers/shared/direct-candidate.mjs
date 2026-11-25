import {mediaFormatFromUrl} from '../../../shared/media-container.mjs';
export function directCandidate(server) {
  if (server?.kind === 'embed' || server?.type === 'embed' || server?.streamType === 'embed') return false;
  try {
    const u = new URL(server?.url || '');
    const demoHost = u.hostname === 'test-videos.co.uk' || u.hostname.endsWith('.test-videos.co.uk');
    return u.protocol === 'https:' && !demoHost && Boolean(mediaFormatFromUrl(u.href));
  } catch { return false; }
}
