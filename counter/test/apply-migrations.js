import { applyD1Migrations, env } from 'cloudflare:test';

// Runs once before the suite: the same migration files wrangler applies
// to production, against the throwaway local database.
await applyD1Migrations(env.DB, env.TEST_MIGRATIONS);
