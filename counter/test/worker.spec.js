import { SELF, env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';

import { MAX_DELTA_CENTS } from '../src/validate.js';

/** Back to an empty world between cases; the schema itself stays. */
beforeEach(async () => {
  await env.DB.prepare(
    'UPDATE totals SET total_cents = 0, contributors = 0, updated_at = NULL WHERE id = 1',
  ).run();
});

/**
 * Each call gets its own rate-limit key unless one is named.
 *
 * The limiter is real in these tests and its window outlives a single
 * case, so sharing a key across tests silently starves the later ones —
 * which is exactly how the first draft of this file failed.
 */
let keys = 0;
function contribute(body, key = `tester-${++keys}`) {
  return SELF.fetch('https://counter.test/api/contributions', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'cf-connecting-ip': key },
    body: JSON.stringify(body),
  });
}

describe('stats', () => {
  it('starts at zero and is readable', async () => {
    const res = await SELF.fetch('https://counter.test/api/stats');
    expect(res.status).toBe(200);
    expect(await res.json()).toMatchObject({ totalCents: 0, contributors: 0 });
  });
});

describe('contributions', () => {
  it('adds deltas to the running total', async () => {
    await contribute({ deltaCents: 80000, firstTime: true });
    const res = await contribute({ deltaCents: 45000, firstTime: false });
    const body = await res.json();
    expect(body.totalCents).toBe(125000);
    // The same person contributing twice counts once.
    expect(body.contributors).toBe(1);
  });

  it('counts each new contributor once', async () => {
    await contribute({ deltaCents: 1000, firstTime: true });
    const res = await contribute({ deltaCents: 1000, firstTime: true });
    expect((await res.json()).contributors).toBe(2);
  });

  it('rejects a bad delta and leaves the total alone', async () => {
    const res = await contribute({ deltaCents: -5 });
    expect(res.status).toBe(400);
    const stats = await (await SELF.fetch('https://counter.test/api/stats')).json();
    expect(stats.totalCents).toBe(0);
  });

  it('rejects an absurd contribution but accepts the maximum', async () => {
    expect((await contribute({ deltaCents: MAX_DELTA_CENTS + 1 })).status).toBe(400);
    expect((await contribute({ deltaCents: MAX_DELTA_CENTS })).status).toBe(200);
  });

  it('rejects an oversized body', async () => {
    const res = await contribute({ deltaCents: 1, pad: 'x'.repeat(4000) });
    expect(res.status).toBe(400);
  });

  it('does not lose an update when contributions land together', async () => {
    // The guard on the single-statement UPDATE. Ten different people
    // burning at the same moment must total ten, not the last one home.
    await Promise.all(
      Array.from({ length: 10 }, (_, i) =>
        contribute({ deltaCents: 100 }, `concurrent-${i}`),
      ),
    );
    const stats = await (await SELF.fetch('https://counter.test/api/stats')).json();
    expect(stats.totalCents).toBe(1000);
  });
});

describe('rate limiting', () => {
  it('cuts one address off past the limit, and leaves others alone', async () => {
    const mine = 'flooder';
    const codes = [];
    for (let i = 0; i < 12; i++) {
      codes.push((await contribute({ deltaCents: 1 }, mine)).status);
    }
    // Ten a minute: the first ten land, the rest are turned away.
    expect(codes.filter((c) => c === 200).length).toBe(10);
    expect(codes).toContain(429);

    // Someone else's budget is untouched by the flood.
    expect((await contribute({ deltaCents: 1 }, 'bystander')).status).toBe(200);
  });

  it('holds under a simultaneous burst', async () => {
    // The case the platform binding fails: forty at once from one caller
    // must still yield exactly ten. Sequential counting would pass this
    // by accident, so it has to be fired in parallel.
    const key = 'burst-caller';
    const results = await Promise.all(
      Array.from({ length: 40 }, () => contribute({ deltaCents: 1 }, key)),
    );
    const ok = results.filter((r) => r.status === 200).length;
    expect(ok).toBe(10);
    expect(results.filter((r) => r.status === 429).length).toBe(30);
  });

  it('does not let a flood inflate the public figure', async () => {
    const before = await (await SELF.fetch('https://counter.test/api/stats')).json();
    await Promise.all(
      Array.from({ length: 40 }, () => contribute({ deltaCents: 100000 }, 'greedy')),
    );
    const after = await (await SELF.fetch('https://counter.test/api/stats')).json();
    // Ten got through, not forty.
    expect(after.totalCents - before.totalCents).toBe(10 * 100000);
  });
});

describe('http surface', () => {
  it('answers preflight', async () => {
    const res = await SELF.fetch('https://counter.test/api/stats', {
      method: 'OPTIONS',
    });
    expect(res.status).toBe(204);
    expect(res.headers.get('access-control-allow-methods')).toMatch(/POST/);
  });

  it('echoes an allowed origin and refuses to echo a stranger', async () => {
    const mine = await SELF.fetch('https://counter.test/api/stats', {
      headers: { origin: 'https://burnmydesire.com' },
    });
    expect(mine.headers.get('access-control-allow-origin')).toBe(
      'https://burnmydesire.com',
    );

    const theirs = await SELF.fetch('https://counter.test/api/stats', {
      headers: { origin: 'https://not-my-site.example' },
    });
    expect(theirs.headers.get('access-control-allow-origin')).not.toBe(
      'https://not-my-site.example',
    );
  });

  it('404s unknown routes', async () => {
    const res = await SELF.fetch('https://counter.test/api/whatever');
    expect(res.status).toBe(404);
  });
});
