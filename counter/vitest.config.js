import path from 'node:path';

import {
  cloudflareTest,
  readD1Migrations,
} from '@cloudflare/vitest-pool-workers';
import { defineConfig } from 'vitest/config';

/**
 * The integration tests run against a real local D1, migrated from the
 * same files production uses — so a schema change that breaks the app
 * breaks the tests first.
 */
const migrations = await readD1Migrations(
  path.join(import.meta.dirname, 'migrations'),
);

export default defineConfig({
  plugins: [
    cloudflareTest({
      singleWorker: true,
      wrangler: { configPath: './wrangler.jsonc' },
      miniflare: {
        bindings: { TEST_MIGRATIONS: migrations },
      },
    }),
  ],
  test: {
    // `node --test` owns *.test.js; vitest owns *.spec.js.
    include: ['test/**/*.spec.js'],
    setupFiles: ['./test/apply-migrations.js'],
  },
});
