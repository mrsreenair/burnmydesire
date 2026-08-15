import { validateContribution } from './validate.js';

/**
 * The entire dataset is three integers.
 *
 * There is deliberately no user table, no install id, no IP log, no
 * timestamps per contribution — the app sends deltas and nothing that
 * could identify who sent them. A breach here would leak "people have
 * burned N euros and M thoughts", which is already published.
 */

export async function addContribution(db, { deltaCents, firstTime, deltaThoughts }) {
  const check = validateContribution({ deltaCents, deltaThoughts });
  if (!check.ok) return check;

  // One statement, so the increment is atomic: no SELECT-then-UPDATE, and
  // therefore no lost update when two people burn at the same moment.
  // Do not "helpfully" split this into a read and a write.
  await db
    .prepare(
      `UPDATE totals
          SET total_cents = total_cents + ?1,
              thoughts = thoughts + ?2,
              contributors = contributors + ?3,
              updated_at = ?4
        WHERE id = 1`,
    )
    .bind(
      check.deltaCents,
      check.deltaThoughts,
      firstTime ? 1 : 0,
      new Date().toISOString(),
    )
    .run();

  return { ok: true };
}

export async function readStats(db) {
  const row = await db
    .prepare(
      'SELECT total_cents, thoughts, contributors, updated_at FROM totals WHERE id = 1',
    )
    .first();

  // A missing row means the migration has not run. Report zero rather
  // than throwing: a stat block that does not render beats a 500.
  return {
    totalCents: row?.total_cents ?? 0,
    thoughts: row?.thoughts ?? 0,
    contributors: row?.contributors ?? 0,
    updatedAt: row?.updated_at ?? null,
  };
}
