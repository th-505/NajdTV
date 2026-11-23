import test from 'node:test';
import assert from 'node:assert/strict';
import {normalizeApiError} from '../server/api-error-response.mjs';

test('public media endpoints share a safe error contract', () => {
  for (const route of ['search', 'catalog', 'resolve', 'playback']) {
    assert.deepEqual(normalizeApiError(`/api/v1/${route}?q=example`, 503, {
      error: 'UPSTREAM_UNAVAILABLE',
      reason: 'ACCESS_BLOCKED',
      cause: 'https://example.invalid/private',
    }), {status: 'error', message: 'UPSTREAM_UNAVAILABLE', reason: 'ACCESS_BLOCKED'});
  }
  assert.equal(normalizeApiError('/api/v1/search', 500, {message: 'internal stack'}).message, 'REQUEST_FAILED');
  const payload = {message: 'ACCESS_BLOCKED'};
  assert.equal(normalizeApiError('/api/v1/browser/search', 503, payload), payload);
});
