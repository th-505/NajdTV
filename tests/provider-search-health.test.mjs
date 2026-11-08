import test from 'node:test';
import assert from 'node:assert/strict';
import { createSearchTraces } from '../server/diagnostics/search-trace.mjs';

test('provider health groups successes, failures and empty results without treating empty as blocking', async () => {
  const traces = createSearchTraces();
  for (let i = 0; i < 3; i++) {
    const t = traces.start({ provider: 'fixture', query: 'test' });
    await assert.rejects(traces.run(t, async () => { throw Object.assign(new Error('ACCESS_BLOCKED'), {code:'ACCESS_BLOCKED'}); }));
  }
  let summary = traces.healthSummary();
  assert.equal(summary.length, 1);
  assert.equal(summary[0].failures, 3);
  assert.equal(summary[0].alert, true);
  const empty = traces.start({ provider: 'fixture', query: 'test' });
  await traces.run(empty, async () => []);
  summary = traces.healthSummary();
  assert.equal(summary[0].empty_unconfirmed, 1);
  assert.equal(summary[0].alert, false);
  const ok = traces.start({ provider: 'fixture', query: 'test' });
  await traces.run(ok, async () => [{title:'test'}]);
  summary = traces.healthSummary();
  assert.equal(summary[0].successes, 1);
  assert.equal(summary[0].consecutive_failures, 0);
  assert.equal(summary[0].attempts, 5);
});
