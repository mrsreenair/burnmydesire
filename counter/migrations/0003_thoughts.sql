-- Thoughts burned, alongside the money.
--
-- A thought has no price, so it could never join the euro total — but it
-- is the same act, and a counter that only reports money implies the
-- money is the only part that counted.
ALTER TABLE totals ADD COLUMN thoughts INTEGER NOT NULL DEFAULT 0;
