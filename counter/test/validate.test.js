import assert from 'node:assert/strict';
import { test } from 'node:test';

import { MAX_DELTA_CENTS, validateContribution } from '../src/validate.js';

test('rejects non-positive and non-integer deltas', () => {
  for (const bad of [0, -100, 1.5, '100', null, undefined, NaN]) {
    assert.equal(validateContribution({ deltaCents: bad }).ok, false);
  }
});

test('rejects an absurd single contribution', () => {
  const result = validateContribution({ deltaCents: MAX_DELTA_CENTS + 1 });
  assert.equal(result.ok, false);
  assert.match(result.reason, /maximum/);
});

test('accepts exactly the maximum', () => {
  assert.equal(validateContribution({ deltaCents: MAX_DELTA_CENTS }).ok, true);
});

test('accepts an ordinary contribution', () => {
  assert.equal(validateContribution({ deltaCents: 12000 }).ok, true);
});
