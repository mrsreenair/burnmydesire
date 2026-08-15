import { validateContribution } from './validate.js';

/**
 * The entire dataset is two integers.
 *
 * There is deliberately no user table, no install id, no IP log, no
 * timestamps per contribution — the app sends a delta and nothing that
 * could identify who sent it. A breach here would leak "people have
 * burned N euros", which is already published on the website.
 */

export async function addContribution(db, { deltaCents, firstTime }) {
  const check = validateContribution({ deltaCents });
  if (!check.ok) return check;

  // One statement, so the increment is atomic: no SELECT-then-UPDATE, and
  // therefore no lost update when two people burn at the same moment.
  // Do not "helpfully" split this into a read and a write.
  await db
    .prepare(
      `UPDATE totals
          SET total_cents = total_cents + ?1,
              contributors = contributors + ?2,
              updated_at = ?3
        WHERE id = 1`,
    )
    .bind(deltaCents, firstTime ? 1 : 0, new Date().toISOString())
    .run();

  return { ok: true };
}

export async function readStats(db) {
  const row = await db
    .prepare(
      'SELECT total_cents, contributors, updated_at FROM totals WHERE id = 1',
    )
    .first();

  // A missing row means the migration has not run. Report zero rather
  // than throwing: a stat block that does not render beats a 500.
  return {
    totalCents: row?.total_cents ?? 0,
    contributors: row?.contributors ?? 0,
    updatedAt: row?.updated_at ?? null,
  };
}
