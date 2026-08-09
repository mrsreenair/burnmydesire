import assert from 'node:assert/strict';
import { test } from 'node:test';

import { RateLimiter } from '../src/rate_limit.js';
import {
  MAX_DELTA_CENTS,
  addContribution,
  openStore,
  readStats,
} from '../src/store.js';

function db() {
  return openStore(':memory:');
}

test('starts empty', () => {
  const stats = readStats(db());
  assert.equal(stats.totalCents, 0);
  assert.equal(stats.contributors, 0);
});

test('adds deltas to the running total', () => {
  const store = db();
  addContribution(store, { deltaCents: 80000, firstTime: true });
  addContribution(store, { deltaCents: 45000, firstTime: false });
  const stats = readStats(store);
  assert.equal(stats.totalCents, 125000);
  // The same person contributing twice counts once.
  assert.equal(stats.contributors, 1);
});

test('counts each new contributor once', () => {
  const store = db();
  addContribution(store, { deltaCents: 1000, firstTime: true });
  addContribution(store, { deltaCents: 1000, firstTime: true });
  assert.equal(readStats(store).contributors, 2);
});

test('rejects non-positive and non-integer deltas', () => {
  const store = db();
  for (const bad of [0, -100, 1.5, '100', null, undefined, NaN]) {
    assert.equal(addContribution(store, { deltaCents: bad }).ok, false);
  }
  assert.equal(readStats(store).totalCents, 0);
});

test('rejects an absurd single contribution', () => {
  const store = db();
  const result = addContribution(store, {
    deltaCents: MAX_DELTA_CENTS + 1,
    firstTime: true,
  });
  assert.equal(result.ok, false);
  assert.equal(readStats(store).totalCents, 0);
});

test('accepts exactly the maximum', () => {
  const store = db();
  assert.equal(
    addContribution(store, { deltaCents: MAX_DELTA_CENTS }).ok,
    true,
  );
});

test('rate limiter allows up to the limit then blocks', () => {
  const limiter = new RateLimiter({ limit: 3, windowMs: 1000 });
  assert.equal(limiter.allow('1.2.3.4', 0), true);
  assert.equal(limiter.allow('1.2.3.4', 10), true);
  assert.equal(limiter.allow('1.2.3.4', 20), true);
  assert.equal(limiter.allow('1.2.3.4', 30), false);
  // A different address has its own budget.
  assert.equal(limiter.allow('5.6.7.8', 30), true);
  // The window rolls over.
  assert.equal(limiter.allow('1.2.3.4', 1100), true);
});
