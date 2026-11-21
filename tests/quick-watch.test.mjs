import test from 'node:test';
import assert from 'node:assert/strict';
import {createQuickWatch} from '../server/quick-watch.mjs';

const row = {name:'sample.m3u8', ref:'source:sample', season:2, episode:3, url:'https://media.example/sample.m3u8'};
const config = {entries: JSON.stringify([row]), key:'ab'.repeat(32)};

test('exact episode links survive restart and reject tampering, expiry and catalog removal', () => {
  const service = createQuickWatch({...config, now:()=>1000});
  assert.equal(service.issue({ref:row.ref, season:2, episode:4}), null);
  const request = {ref:row.ref, season:2, episode:3};
  const link = service.issue(request);
  assert.notEqual(link, service.issue(request));
  const [, , token, name] = new URL(link).pathname.split('/');
  assert.equal(createQuickWatch({...config, now:()=>1001}).resolve(token,name), row.url);
  assert.equal(service.resolve(token.slice(0,-1)+(token.endsWith('0')?'1':'0'),name),null);
  assert.equal(createQuickWatch({...config, now:()=>1000+365*86400}).resolve(token,name),null);
  assert.equal(createQuickWatch({entries:'[]'}).resolve(token,name),null);
});

test('user payload cannot select arbitrary destinations; signed upstream URLs are rejected', () => {
  assert.equal(createQuickWatch(config).issue({url:'https://other.example/video.mp4'}),null);
  assert.throws(()=>createQuickWatch({...config,entries:JSON.stringify([{...row,url:row.url+'?token=secret'}])}));
});
