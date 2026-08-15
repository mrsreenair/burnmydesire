-- The whole schema: one row, two integers.
--
-- The CHECK pins the table to a single row, so there is no way for a bug
-- to start accumulating a second total alongside the real one.
CREATE TABLE IF NOT EXISTS totals (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  total_cents INTEGER NOT NULL DEFAULT 0,
  contributors INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT
);

INSERT OR IGNORE INTO totals (id, total_cents, contributors) VALUES (1, 0, 0);
