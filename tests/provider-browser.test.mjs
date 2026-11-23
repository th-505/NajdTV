import test from 'node:test';
import assert from 'node:assert/strict';
import { createProviderBrowser } from '../server/scrapers/provider-browser.mjs';

test('provider browsing keeps the selected source and registered categories', async () => {
  const calls = [];
  const meta = { id: 'one', name: 'One', domains: ['https://one.example'], capabilities: { catalog: true } };
  const browser = createProviderBrowser({ providers: () => [meta], lookup: id => id === 'one' ? {
    meta, module: { CONFIG: { categories: { series: '/series/' } },
      async scrapeCatalog(category, page) {
        calls.push([category, page]);
        const items = [{ ref: 'one:series-1', title: 'Series', source: 'incorrect' }];
        Object.defineProperty(items, '_meta', { value: { next_page: 2 } });
        return items;
      },
    },
  } : null });
  assert.equal(browser.sources()[0].categories[0].id, 'series');
  const result = await browser.catalog('one', '', 1);
  assert.deepEqual(calls, [['series', 1]]);
  assert.equal(result.items[0].source, 'one');
  assert.deepEqual(result.items[0].source_refs, { one: 'one:series-1' });
  assert.equal(result.pagination.has_more, true);
  await assert.rejects(() => browser.catalog('one', 'https://127.0.0.1/', 1), /BAD_CATEGORY/);
  await assert.rejects(() => browser.catalog('one', 'series', 0), /BAD_PAGE/);
  await assert.rejects(() => browser.catalog('missing', '', 1), /UNAVAILABLE/);
  assert.equal(calls.length, 1, 'invalid routes must never invoke a scraper');
});

test('successful metadata is coalesced and bounded, while failures and empty pages are never cached',async()=>{
 let calls=0,release;const gate=new Promise(r=>release=r);let clock=100;
 const meta={id:'sample',name:'Sample',domains:['https://sample.example'],capabilities:{catalog:true,live:true}};
 const browser=createProviderBrowser({now:()=>clock,catalogTtlMs:1000,providers:()=>[meta],lookup:()=>({meta,module:{CONFIG:{categories:{live:'/'}},scrapeCatalog:async()=>{calls++;await gate;return[{ref:'sample:observed',title:'Observed',type:'live'}]}}})});
 assert.equal(browser.sources()[0].content_type,'live');
 const a=browser.catalog('sample','live'),b=browser.catalog('sample','live');await new Promise(r=>setImmediate(r));assert.equal(calls,1);release();const[first,second]=await Promise.all([a,b]);first.items[0].title='caller mutation';assert.equal(second.items[0].title,'Observed');assert.equal((await browser.catalog('sample','live')).items[0].title,'Observed');assert.equal(calls,1);clock+=1001;await browser.catalog('sample','live');assert.equal(calls,2);
 let attempts=0;const fail=createProviderBrowser({providers:()=>[meta],lookup:()=>({meta,module:{CONFIG:{categories:{live:'/'}},scrapeCatalog:async()=>{attempts++;if(attempts===1)throw Object.assign(Error('blocked'),{code:'ACCESS_BLOCKED'});return[];}}})});
 await assert.rejects(()=>fail.catalog('sample','live'),/SOURCE_UNAVAILABLE/);await fail.catalog('sample','live');await fail.catalog('sample','live');assert.equal(attempts,3);
});

test('hybrid VOD providers retain their film and episode catalogue outside the live-only section',()=>{
 const meta={id:'hybrid',name:'Hybrid',domains:['https://example.com'],capabilities:{catalog:true,live:true,episodes:true}};
 const browser=createProviderBrowser({providers:()=>[meta],lookup:()=>({meta,module:{scrapeCatalog:async()=>[]}})});
 assert.equal(browser.sources()[0].content_type,'vod');
});

test('observed next URLs remain private, expire and cannot cross a provider or category',async()=>{
 let clock=100;const calls=[];
 const lookup=id=>({meta:{id,name:id,domains:['https://'+id+'.example'],capabilities:{catalog:true}},module:{CONFIG:{categories:{movies:'/',series:'/series/'}},scrapeCatalog:async(category,page,options)=>{
  calls.push({id,category,page,next:options.searchPageUrl});
  const rows=[{ref:id+':'+page,title:'Observed'}];
  Object.defineProperty(rows,'_meta',{value:{next_page:page===1?2:null,next_url:'https://one.example/observed/?cursor=public-metadata'}});return rows;
 }}});
 const browser=createProviderBrowser({lookup,now:()=>clock,catalogTtlMs:1000});
 const first=await browser.catalog('one','movies',1);
 assert(!JSON.stringify(first).includes('cursor='),'upstream pagination URLs are server-private metadata');
 await browser.catalog('one','movies',2);
 assert.equal(calls.at(-1).next,'https://one.example/observed/?cursor=public-metadata');
 await browser.catalog('one','series',2);assert.equal(calls.at(-1).next,undefined);
 await browser.catalog('two','movies',1);await browser.catalog('two','movies',2);
 assert.equal(calls.at(-1).next,undefined,'foreign-host pagination must be rejected');
 clock+=1001;await browser.catalog('one','movies',2);
 assert.equal(calls.at(-1).next,undefined,'expired page evidence must never be reused');
});

test('Beta catalog preserves guarded Brstej errors without requesting rejected destinations', async t => {
  const beta = await import('../server/browser/providers/sites/brstej.mjs');
  const initialUrl = beta.BRSTEJ_CONFIG.baseUrl + '/home03';
  const scenarios = [
    ['foreign redirect', 'UNSAFE_URL', /^HOST_NOT_IN_ALLOWLIST:/, [
      new Response(null, {status: 302, headers: {location: 'https://unrelated.example/home03'}}),
    ]],
    ['HTTP redirect', 'UNSAFE_URL', /^PROTOCOL_NOT_ALLOWED:/, [
      new Response(null, {status: 302, headers: {location: initialUrl.replace('https:', 'http:')}}),
    ]],
    ['DNS rejected', 'UNSAFE_URL', /^SSRF_DNS_RESOLVED_TO_PRIVATE_IP:/, [], '127.0.0.1'],
    ['timeout', 'NETWORK_TIMEOUT', /TimeoutError/, [new DOMException('TimeoutError', 'TimeoutError')]],
    ['blocked', 'ACCESS_BLOCKED', /^CLOUDFLARE_OR_WAF_CHALLENGE/, [
      new Response('<title>Just a moment...</title>', {status: 403, headers: {'cf-mitigated': 'challenge'}}),
    ]],
  ];
  for (const [name, code, check, responses, address] of scenarios) {
    await t.test(name, async () => {
      const calls = [];
      const browser = createProviderBrowser({
        lookup: () => ({
          meta: beta.PROVIDER_META,
          module: {
            CONFIG: beta.BRSTEJ_CONFIG,
            scrapeCatalog: (category, page, options) => beta.scrapeCatalog(category, page, {
              ...options,
              dnsLookupImpl: async () => [{address: address ?? '93.184.216.34'}],
              fetchImpl: async url => {
                const response = responses[calls.length];
                calls.push(url);
                if (response instanceof Error) throw response;
                assert.ok(response, 'unexpected upstream request');
                return response;
              },
            }),
          },
        }),
      });
      await assert.rejects(browser.catalog('brstej', 'latest', 1), error => {
        assert.equal(error.message, 'BROWSER_SOURCE_UNAVAILABLE');
        assert.equal(error.code, code);
        assert.equal(error.cause.code, code);
        assert.match(error.cause.message, check);
        return true;
      });
      assert.deepEqual(calls, responses.length ? [initialUrl] : []);
    });
  }
});

test('catalog HTTP correlates sanitized 503 diagnostics and keeps 400 unchanged', async t => {
  const { createServer } = await import('../server/app.mjs');
  const log = t.mock.method(console, 'log', () => {});
  const server = createServer({
    catalogStore: null,
    harvestService: {start() {}, async stop() {}},
    browserConfigurationService: {async refresh() {}, close() {}},
    providerBrowser: {
      async catalog(provider, category, page) {
        if (page === 0) throw Error('BROWSER_BAD_PAGE');
        assert.deepEqual([provider, category], ['brstej', 'latest']);
        if (page === 6) {
          throw Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE'), {
            code: 'ACCESS_BLOCKED', catalogCacheHit: true, retryAfterSeconds: 12,
          });
        }
        if (page === 7) {
          throw Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE'), {
            code: 'ACCESS_BLOCKED', circuitOpen: true, retryAfterSeconds: 'invalid',
          });
        }
        const scenarios = {
          1: ['UNSAFE_URL', 'HOST_NOT_IN_ALLOWLIST: unrelated.example'],
          2: ['ACCESS_BLOCKED', 'CLOUDFLARE_OR_WAF_CHALLENGE_HTTP_403', 403],
          3: ['ACCESS_BLOCKED', 'fetch failed', null, 'EAI_AGAIN'],
          4: ['ACCESS_BLOCKED', 'HTTP_429_FETCHING_https://unrelated.example/private-path', 429],
          5: ['ACCESS_BLOCKED', 'UPSTREAM_HOST_COOLDOWN', 429],
        };
        const [code, message, status, networkCode] = scenarios[page];
        const cause = Object.assign(Error(message), {
          url: 'https://unrelated.example/private-path?token=private-value',
          status,
          cause: networkCode
            ? Error('fetch failed', {cause: Object.assign(Error('private-value'), {code: networkCode})})
            : null,
        });
        throw Object.assign(Error('BROWSER_SOURCE_UNAVAILABLE', {cause}), {code});
      },
    },
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const endpoint = `http://127.0.0.1:${server.address().port}/api/v1/browser/catalog?provider=brstej&category=latest`;
    const response = await fetch(endpoint + '&page=1');
    const body = await response.json();
    assert.equal(response.status, 503);
    assert.match(body.trace_id, /^[0-9a-f-]{36}$/);
    assert.equal(response.headers.get('x-trace-id'), body.trace_id);
    assert.deepEqual([body.reason, body.provider, body.category, body.page], ['UNSAFE_URL', 'brstej', 'latest', 1]);
    const logs = log.mock.calls.flatMap(call => call.arguments).filter(value =>
      typeof value === 'string' && value.includes('browser_catalog_failed'));
    assert.equal(logs.length, 1);
    const event = JSON.parse(logs[0]);
    assert.equal(event.check, 'HOST_NOT_IN_ALLOWLIST');
    assert.equal(event.trace_id, body.trace_id);
    assert.equal(event.host, 'unrelated.example');
    assert.doesNotMatch(logs[0] + JSON.stringify(body), /https:\/\/|private-path|private-value/);
    assert.equal(body.host, undefined);

    for (const [page, check, status] of [
      [2, 'UPSTREAM_CHALLENGE', 403], [3, 'EAI_AGAIN', undefined],
      [4, 'UPSTREAM_HTTP_ERROR', 429], [5, 'UPSTREAM_HOST_COOLDOWN', undefined],
    ]) {
      const result = await fetch(endpoint + '&page=' + page);
      const payload = await result.json();
      const line = log.mock.calls.flatMap(call => call.arguments).find(value =>
        typeof value === 'string' && value.includes(payload.trace_id));
      const diagnostic = JSON.parse(line);
      assert.equal(result.status, 503);
      assert.equal(diagnostic.check, check);
      assert.equal(diagnostic.host, 'unrelated.example');
      assert.equal(diagnostic.upstream_status, status);
      assert.doesNotMatch(line + JSON.stringify(payload), /https:\/\/|private-path|private-value/);
    }

    const cached = await fetch(endpoint + '&page=6');
    assert.equal(cached.status, 503);
    assert.equal(cached.headers.get('retry-after'), '12');
    const cachedBody = await cached.json();
    const cachedLog = log.mock.calls.flatMap(call => call.arguments).find(value =>
      typeof value === 'string' && value.includes(cachedBody.trace_id));
    assert.equal(JSON.parse(cachedLog).check, 'CACHED_ACCESS_BLOCKED');
    assert.equal(cachedBody.reason, 'ACCESS_BLOCKED');

    const invalidRetry = await fetch(endpoint + '&page=7');
    assert.equal(invalidRetry.status, 503);
    assert.equal(invalidRetry.headers.get('retry-after'), null);

    const invalid = await fetch(endpoint + '&page=0');
    assert.equal(invalid.status, 400);
    assert.equal(invalid.headers.get('x-trace-id'), null);
    assert.equal((await invalid.json()).message, 'BROWSER_BAD_PAGE');
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});

test('Beta Brstej deduplicates blocked pages for 30 seconds without suppressing other providers', async () => {
  let clock = 10_000;
  let attempts = 0;
  const browser = createProviderBrowser({
    now: () => clock,
    lookup: id => ({
      meta: {id, name: id, domains: [`https://${id}.example`], capabilities: {catalog: true}},
      module: {
        CONFIG: {categories: {latest: '/'}},
        async scrapeCatalog() {
          if (id === 'brstej' && ++attempts === 1) {
            throw Object.assign(Error('CLOUDFLARE_OR_WAF_CHALLENGE_HTTP_403'), {code: 'ACCESS_BLOCKED'});
          }
          return [{ref: `${id}:item`, title: 'An available result'}];
        },
      },
    }),
  });

  await assert.rejects(browser.catalog('brstej', 'latest'), {code: 'ACCESS_BLOCKED'});
  await assert.rejects(browser.catalog('brstej', 'latest'), {
    code: 'ACCESS_BLOCKED', catalogCacheHit: true, retryAfterSeconds: 30,
  });
  assert.equal(attempts, 1);
  assert.equal((await browser.catalog('other', 'latest')).items[0].source, 'other');
  clock += 29_999;
  await assert.rejects(browser.catalog('brstej', 'latest'), {catalogCacheHit: true});
  clock += 1;
  assert.equal((await browser.catalog('brstej', 'latest')).items[0].source, 'brstej');
  assert.equal(attempts, 2);
});

test('Beta Brstej search caches blocked responses without logging the query', async t => {
  const {createServer} = await import('../server/app.mjs');
  const log = t.mock.method(console, 'log', () => {});
  let clock = 10_000;
  let attempts = 0;
  const browser = createProviderBrowser({
    now: () => clock,
    lookup: id => ({
      meta: {id, domains: [`https://${id}.example`]},
      module: {
        async scrapeSearch() {
          if (id === 'brstej' && ++attempts === 1) {
            throw Object.assign(Error('CLOUDFLARE_OR_WAF_CHALLENGE_HTTP_403'), {code: 'ACCESS_BLOCKED'});
          }
          return [{title: 'Available work', ref: `${id}:result`}];
        },
      },
    }),
  });
  const server = createServer({
    catalogStore: null,
    harvestService: {start() {}, async stop() {}},
    browserConfigurationService: {async refresh() {}, close() {}},
    providerBrowser: browser,
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  try {
    const run = (provider, q = 'private-search-term') => {
      const params = new URLSearchParams({provider, q, page: '1'});
      return fetch(`http://127.0.0.1:${server.address().port}/api/v1/browser/search?${params}`);
    };
    const first = await run('brstej');
    assert.equal(first.status, 503);
    assert.deepEqual(await first.json(), {message: 'ACCESS_BLOCKED'});
    assert.equal(first.headers.get('retry-after'), null);

    const cached = await run('brstej', '  private-search-term  ');
    assert.equal(cached.status, 503);
    assert.equal(cached.headers.get('retry-after'), '30');
    assert.deepEqual(await cached.json(), {message: 'ACCESS_BLOCKED'});
    assert.equal(attempts, 1);
    const line = log.mock.calls.flatMap(call => call.arguments).find(value =>
      typeof value === 'string' && value.includes(cached.headers.get('x-trace-id')));
    assert.equal(JSON.parse(line).check, 'CACHED_ACCESS_BLOCKED');
    assert.doesNotMatch(line, /private-search-term|https?:/);

    assert.equal((await run('other')).status, 200);
    assert.equal((await run('brstej', 'distinct search')).status, 200);
    assert.equal(attempts, 2);
    clock += 29_999;
    assert.equal((await run('brstej')).headers.get('retry-after'), '1');
    clock += 1;
    assert.equal((await run('brstej')).status, 200);
    assert.equal(attempts, 3);
  } finally {
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
  }
});

test('Brstej breaker spans search and catalog while leaving other providers available', async () => {
  let clock = 1000;
  let calls = 0;
  let blocked = true;
  const browser = createProviderBrowser({
    now: () => clock,
    lookup: id => {
      const load = async () => {
        if (id === 'brstej') {
          calls++;
          if (blocked) throw Object.assign(Error('blocked'), {code: 'ACCESS_BLOCKED'});
        }
        return [{ref: `${id}:work`, title: 'Work'}];
      };
      return {
        meta: {id, domains: [`https://${id}.example`]},
        module: {CONFIG: {categories: {latest: '/'}}, scrapeSearch: load, scrapeCatalog: load},
      };
    },
  });
  await assert.rejects(browser.catalog('brstej', 'latest'), {code: 'ACCESS_BLOCKED'});
  await assert.rejects(browser.search('brstej', 'احلى نصيب'), {code: 'ACCESS_BLOCKED'});
  await assert.rejects(browser.search('brstej', 'Another work'), {code: 'ACCESS_BLOCKED'});
  await assert.rejects(browser.catalog('brstej', 'latest', 2), {circuitOpen: true, retryAfterSeconds: 30});
  assert.equal(calls, 3);
  assert.equal((await browser.catalog('3isk', 'latest')).items.length, 1);
  assert.equal((await browser.search('animezid', 'One Piece')).length, 1);
  clock += 30_000;
  blocked = false;
  assert.equal((await browser.search('brstej', 'احلى نصيب')).length, 1);
  assert.equal((await browser.catalog('brstej', 'latest', 2)).items.length, 1);
  const stats = browser.health().find(row => row.provider === 'brstej');
  assert.deepEqual(stats, {
    provider: 'brstej', attempts: 5, successes: 2, average_ms: 0, last_error: 'ACCESS_BLOCKED',
  });
  assert.equal(calls, 5);
});
