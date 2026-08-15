import {
  DEFAULT_LIMIT,
  DEFAULT_WINDOW_SECONDS,
  allow,
  shouldSweep,
  sweep,
} from './rate_limit.js';
import { addContribution, readStats } from './store.js';

/**
 * The counter, as a Worker.
 *
 * Two routes and two integers. Everything that made the Node version
 * long — an HTTP server, a stream reader, a hand-rolled rate limiter —
 * is either a platform primitive here or a binding, so what is left is
 * the actual rules.
 */

const BODY_LIMIT_BYTES = 1024;

/** Comma-separated origins allowed to read the stats, or * for any. */
function allowedOrigins(env) {
  return (env.ALLOWED_ORIGINS ?? '*')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

function corsHeaders(env, origin) {
  const allowed = allowedOrigins(env);
  const allow =
    allowed.includes('*') || (origin && allowed.includes(origin))
      ? (origin ?? '*')
      : allowed[0];
  return {
    'access-control-allow-origin': allow,
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
    'access-control-max-age': '86400',
    // The origin decides the response, so caches must not share it.
    vary: 'Origin',
  };
}

function json(env, origin, status, body, { cacheSeconds = 0 } = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      // A public aggregate is worth caching at the edge; anything that
      // reflects a specific request is not.
      'cache-control': cacheSeconds
        ? `public, max-age=${cacheSeconds}, s-maxage=${cacheSeconds}`
        : 'no-store',
      ...corsHeaders(env, origin),
    },
  });
}

async function readJson(request) {
  const declared = Number(request.headers.get('content-length') ?? 0);
  if (declared > BODY_LIMIT_BYTES) throw new Error('body too large');
  const text = await request.text();
  if (text.length > BODY_LIMIT_BYTES) throw new Error('body too large');
  if (!text) return {};
  return JSON.parse(text);
}

/**
 * True when the request may proceed.
 *
 * Two passes. The platform binding is free and needs no database, so it
 * absorbs the bulk of a flood before it can cost us D1 writes — but it
 * only approximates, so it cannot be the whole answer. The D1 counter
 * behind it is exact, and it is the one that decides.
 */
async function withinRateLimit(request, env, ctx) {
  const key = request.headers.get('cf-connecting-ip') ?? 'unknown';

  if (env.CONTRIBUTION_LIMIT) {
    const { success } = await env.CONTRIBUTION_LIMIT.limit({ key });
    if (!success) return false;
  }

  const verdict = await allow(env.DB, key, {
    salt: env.RATE_SALT,
    limit: Number(env.RATE_LIMIT ?? DEFAULT_LIMIT),
    windowSeconds: Number(env.RATE_WINDOW_SECONDS ?? DEFAULT_WINDOW_SECONDS),
  });

  // Housekeeping happens after the response, and only now and then.
  if (shouldSweep()) ctx?.waitUntil?.(sweep(env.DB));

  return verdict.ok;
}

export default {
  async fetch(request, env, ctx) {
    const origin = request.headers.get('origin');
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(env, origin) });
    }

    if (request.method === 'GET' && url.pathname === '/api/stats') {
      // A minute. Long enough that a page view is nearly always served
      // from the edge rather than costing a Worker invocation and a D1
      // query, short enough that the site's toast can notice a burn
      // while someone is still on the page.
      return json(env, origin, 200, await readStats(env.DB), {
        cacheSeconds: 60,
      });
    }

    if (request.method === 'POST' && url.pathname === '/api/contributions') {
      if (!(await withinRateLimit(request, env, ctx))) {
        return json(env, origin, 429, { error: 'too many requests' });
      }

      let body;
      try {
        body = await readJson(request);
      } catch {
        return json(env, origin, 400, { error: 'invalid body' });
      }

      const result = await addContribution(env.DB, {
        deltaCents: body.deltaCents,
        firstTime: body.firstTime === true,
      });
      if (!result.ok) {
        return json(env, origin, 400, { error: result.reason });
      }
      return json(env, origin, 200, await readStats(env.DB));
    }

    return json(env, origin, 404, { error: 'not found' });
  },
};
