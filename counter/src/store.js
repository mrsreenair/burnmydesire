import Database from 'better-sqlite3';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

/**
 * The entire dataset is two integers.
 *
 * There is deliberately no user table, no install id, no IP log, no
 * timestamps per contribution — the app sends a delta and nothing that
 * could identify who sent it. A breach here would leak "people have
 * burned N euros", which is already published on the website.
 */
export function openStore(file) {
  if (file !== ':memory:') mkdirSync(dirname(file), { recursive: true });
  const db = new Database(file);
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS totals (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      total_cents INTEGER NOT NULL DEFAULT 0,
      contributors INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT
    );
    INSERT OR IGNORE INTO totals (id, total_cents, contributors)
      VALUES (1, 0, 0);
  `);
  return db;
}

/** Largest single contribution accepted, in cents (€1,000,000). */
export const MAX_DELTA_CENTS = 100_000_000;

export function addContribution(db, { deltaCents, firstTime }) {
  if (!Number.isInteger(deltaCents) || deltaCents <= 0) {
    return { ok: false, reason: 'delta_cents must be a positive integer' };
  }
  if (deltaCents > MAX_DELTA_CENTS) {
    // A single absurd number would distort a public figure permanently.
    return { ok: false, reason: 'delta_cents exceeds the accepted maximum' };
  }
  db.prepare(
    `UPDATE totals
        SET total_cents = total_cents + ?,
            contributors = contributors + ?,
            updated_at = ?
      WHERE id = 1`,
  ).run(deltaCents, firstTime ? 1 : 0, new Date().toISOString());
  return { ok: true };
}

export function readStats(db) {
  const row = db
    .prepare(
      'SELECT total_cents, contributors, updated_at FROM totals WHERE id = 1',
    )
    .get();
  return {
    totalCents: row.total_cents,
    contributors: row.contributors,
    updatedAt: row.updated_at,
  };
}
