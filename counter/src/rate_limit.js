/**
 * A rate limiter that actually limits.
 *
 * The platform binding is documented as a loose filter — each isolate
 * checks a locally cached count, so a burst passes before the count
 * propagates. Measured against the deployed Worker, forty parallel
 * requests all succeeded against a limit of ten. For a public figure
 * that is append-only and cannot be corrected, "approximately ten" is
 * not a limit.
 *
 * So the binding stays in front as a free first pass, and this is the
 * backstop that counts exactly.
 */

export const DEFAULT_LIMIT = 10;
export const DEFAULT_WINDOW_SECONDS = 60;

/** How often a write also sweeps away windows that have passed. */
const SWEEP_CHANCE = 0.02;

/**
 * The stored key is a salted hash, so the table never holds an address.
 *
 * The salt is a deployment secret rather than the old per-process random
 * value: rows have to stay comparable across isolates for the count to
 * mean anything. Without the secret set, the hash still stands between
 * the table and a raw IP, just with less to stop an offline guess.
 */
async function hashKey(key, salt) {
  const data = new TextEncoder().encode(`${salt ?? 'unsalted'}:${key}`);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * Records one request and reports whether it may proceed.
 *
 * The insert-or-bump is a single statement with RETURNING, so two
 * requests landing together cannot both read "9" and both write "10".
 */
export async function allow(db, key, { salt, limit, windowSeconds, now } = {}) {
  const cap = limit ?? DEFAULT_LIMIT;
  const width = windowSeconds ?? DEFAULT_WINDOW_SECONDS;
  const seconds = Math.floor((now ?? Date.now()) / 1000);
  const windowStart = Math.floor(seconds / width) * width;

  const hash = await hashKey(key, salt);

  const row = await db
    .prepare(
      `INSERT INTO rate_limit (key_hash, window_start, count)
            VALUES (?1, ?2, 1)
       ON CONFLICT(key_hash) DO UPDATE SET
            count = CASE
                      WHEN rate_limit.window_start = ?2 THEN rate_limit.count + 1
                      ELSE 1
                    END,
            window_start = ?2
         RETURNING count`,
    )
    .bind(hash, windowStart)
    .first();

  return { ok: (row?.count ?? 1) <= cap, count: row?.count ?? 1, windowStart };
}

/** Drops rows whose window has passed, so the table cannot grow forever. */
export async function sweep(db, { windowSeconds, now } = {}) {
  const width = windowSeconds ?? DEFAULT_WINDOW_SECONDS;
  const seconds = Math.floor((now ?? Date.now()) / 1000);
  const current = Math.floor(seconds / width) * width;
  await db
    .prepare('DELETE FROM rate_limit WHERE window_start < ?1')
    .bind(current)
    .run();
}

export function shouldSweep(roll = Math.random()) {
  return roll < SWEEP_CHANCE;
}
