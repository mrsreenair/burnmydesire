process.env.NODE_ENV = 'test';
process.env.DB_FILE = ':memory:';
process.env.ALLOWED_ORIGINS = '*';

import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';

const { server } = await import('../src/server.js');

let base;

before(async () => {
  await new Promise((resolve) => server.listen(0, resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => server.close());

test('health responds', async () => {
  const res = await fetch(`${base}/health`);
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { ok: true });
});

test('stats start at zero and stay public', async () => {
  const res = await fetch(`${base}/api/stats`);
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('access-control-allow-origin'), '*');
  const body = await res.json();
  assert.equal(body.totalCents, 0);
});

test('a contribution moves the total', async () => {
  const res = await fetch(`${base}/api/contributions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ deltaCents: 120000, firstTime: true }),
  });
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.totalCents, 120000);
  assert.equal(body.contributors, 1);
});

test('rejects a bad delta', async () => {
  const res = await fetch(`${base}/api/contributions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ deltaCents: -5 }),
  });
  assert.equal(res.status, 400);
});

test('rejects an oversized body', async () => {
  const res = await fetch(`${base}/api/contributions`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ deltaCents: 1, pad: 'x'.repeat(4000) }),
  });
  assert.equal(res.status, 400);
});

test('preflight is answered', async () => {
  const res = await fetch(`${base}/api/stats`, { method: 'OPTIONS' });
  assert.equal(res.status, 204);
  assert.match(res.headers.get('access-control-allow-methods'), /POST/);
});

test('unknown routes 404', async () => {
  const res = await fetch(`${base}/api/whatever`);
  assert.equal(res.status, 404);
});
