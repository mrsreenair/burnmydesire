/**
 * The rules a contribution has to pass, with no database in sight.
 *
 * Kept separate from the store so it stays testable under plain
 * `node --test` — the D1 binding only exists inside a Worker, and the
 * interesting cases here are all arithmetic.
 */

/** Largest single contribution accepted, in cents (€1,000,000). */
export const MAX_DELTA_CENTS = 100_000_000;

/** Largest number of thoughts one contribution may add. */
export const MAX_DELTA_THOUGHTS = 10_000;

function checkCount(value, max, name) {
  if (value === undefined || value === null) return { ok: true, value: 0 };
  if (!Number.isInteger(value) || value < 0) {
    return { ok: false, reason: `${name} must be a non-negative integer` };
  }
  if (value > max) {
    // A single absurd number would distort a public figure permanently.
    return { ok: false, reason: `${name} exceeds the accepted maximum` };
  }
  return { ok: true, value };
}

/**
 * Money, thoughts, or both — but not nothing.
 *
 * Older builds of the app send only deltaCents and know nothing about
 * thoughts; those stay valid, and their thought count is zero.
 */
export function validateContribution({ deltaCents, deltaThoughts }) {
  const cents = checkCount(deltaCents, MAX_DELTA_CENTS, 'delta_cents');
  if (!cents.ok) return cents;

  const thoughts = checkCount(deltaThoughts, MAX_DELTA_THOUGHTS, 'delta_thoughts');
  if (!thoughts.ok) return thoughts;

  if (cents.value === 0 && thoughts.value === 0) {
    return { ok: false, reason: 'a contribution must add something' };
  }

  return { ok: true, deltaCents: cents.value, deltaThoughts: thoughts.value };
}
