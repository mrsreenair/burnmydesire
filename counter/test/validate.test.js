import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  MAX_DELTA_CENTS,
  MAX_DELTA_THOUGHTS,
  validateContribution,
} from '../src/validate.js';

test('rejects non-integer and negative money', () => {
  for (const bad of [-100, 1.5, '100', NaN]) {
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

test('a contribution has to add something', () => {
  assert.equal(validateContribution({}).ok, false);
  assert.equal(validateContribution({ deltaCents: 0 }).ok, false);
  assert.equal(
    validateContribution({ deltaCents: 0, deltaThoughts: 0 }).ok,
    false,
  );
});

test('thoughts alone are a valid contribution', () => {
  const result = validateContribution({ deltaThoughts: 3 });
  assert.equal(result.ok, true);
  assert.equal(result.deltaCents, 0);
  assert.equal(result.deltaThoughts, 3);
});

test('money alone still works, as older app builds send it', () => {
  const result = validateContribution({ deltaCents: 500 });
  assert.equal(result.ok, true);
  assert.equal(result.deltaThoughts, 0);
});

test('rejects bad thought counts', () => {
  for (const bad of [-1, 2.5, '3']) {
    assert.equal(validateContribution({ deltaThoughts: bad }).ok, false);
  }
  assert.equal(
    validateContribution({ deltaThoughts: MAX_DELTA_THOUGHTS + 1 }).ok,
    false,
  );
  assert.equal(
    validateContribution({ deltaThoughts: MAX_DELTA_THOUGHTS }).ok,
    true,
  );
});
