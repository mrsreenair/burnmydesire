/**
 * The rules a contribution has to pass, with no database in sight.
 *
 * Kept separate from the store so it stays testable under plain
 * `node --test` — the D1 binding only exists inside a Worker, and the
 * interesting cases here are all arithmetic.
 */

/** Largest single contribution accepted, in cents (€1,000,000). */
export const MAX_DELTA_CENTS = 100_000_000;

export function validateContribution({ deltaCents }) {
  if (!Number.isInteger(deltaCents) || deltaCents <= 0) {
    return { ok: false, reason: 'delta_cents must be a positive integer' };
  }
  if (deltaCents > MAX_DELTA_CENTS) {
    // A single absurd number would distort a public figure permanently.
    return { ok: false, reason: 'delta_cents exceeds the accepted maximum' };
  }
  return { ok: true };
}
