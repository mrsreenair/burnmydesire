-- Fixed-window request counts, one row per caller per window.
--
-- The key is a salted hash, never an address: the table can count a
-- repeat caller without holding anything that identifies one. Rows are
-- disposable — a sweep drops them once their window has passed.
CREATE TABLE IF NOT EXISTS rate_limit (
  key_hash TEXT PRIMARY KEY,
  window_start INTEGER NOT NULL,
  count INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS rate_limit_window ON rate_limit (window_start);
