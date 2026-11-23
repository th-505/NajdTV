const routes = new Set(['/api/v1/search', '/api/v1/catalog', '/api/v1/resolve', '/api/v1/playback']);
const errorCode = /^[A-Z][A-Z0-9_]{2,79}$/;

export function normalizeApiError(requestUrl, status, payload) {
  if (status < 400 || !routes.has(requestUrl?.split('?', 1)[0])) return payload;
  const message = [payload?.message, payload?.error_code, payload?.error].find(
    value => typeof value === 'string' && errorCode.test(value),
  ) ?? 'REQUEST_FAILED';
  const reason = typeof payload?.reason === 'string' && errorCode.test(payload.reason)
    ? payload.reason : message;
  return {status: 'error', message, reason};
}
