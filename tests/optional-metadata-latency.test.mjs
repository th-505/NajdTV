import test from 'node:test';
import assert from 'node:assert/strict';
import {createBrowserConfiguration} from '../server/browser/configuration.mjs';
import {createCatalogMetadataCache} from '../server/catalog-metadata-cache.mjs';
test('provider listing survives an unresponsive optional configuration DB', async () => {
  const config = createBrowserConfiguration({ budgetMs: 20, store: { configs: () => new Promise(() => {}) } });
  try {
    const started = performance.now();
    await config.refresh();
    assert.ok(performance.now() - started < 300);
    assert.equal(config.status().cloud_available, false);
  } finally { config.close(); }
});
test('metadata response never waits for an optional counter write', async () => {
  const ref = 'laroza:fixture';
  const cache = createCatalogMetadataCache({ validateRef: () => 'laroza',
    store: { get: async () => null, touch: () => new Promise(() => {}) },
    load: async () => ({ title: 'Fixture', type: 'movie' }) });
  const started = performance.now();
  const result = await cache.get(ref);
  assert.equal(result.title, 'Fixture');
  assert.ok(performance.now() - started < 200);
});
test('metadata falls back to the trusted loader within the read budget when DB hangs', async () => {
  const cache = createCatalogMetadataCache({ validateRef: () => 'laroza',
    store: { get: () => new Promise(() => {}), touch: async () => {} }, load: async () => ({ title: 'Fixture' }) });
  const started = performance.now();
  assert.equal((await cache.get('laroza:fixture')).title, 'Fixture');
  assert.ok(performance.now() - started < 1000);
});
