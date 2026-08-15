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

function json(env, origin, status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store',
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
 * The Node version hashed the address with a per-process salt so the
 * limiter could count without keeping anything identifying. The binding
 * keeps that property for free: the key is handed over per request and
 * never stored anywhere we can read.
 *
 * Absent binding means allow — local `vitest` runs without one, and a
 * counter that refuses every write is worse than one that is briefly
 * unlimited.
 */
async function withinRateLimit(request, env) {
  if (!env.CONTRIBUTION_LIMIT) return true;
  const key = request.headers.get('cf-connecting-ip') ?? 'unknown';
  const { success } = await env.CONTRIBUTION_LIMIT.limit({ key });
  return success;
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('origin');
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(env, origin) });
    }

    if (request.method === 'GET' && url.pathname === '/api/stats') {
      return json(env, origin, 200, await readStats(env.DB));
    }

    if (request.method === 'POST' && url.pathname === '/api/contributions') {
      if (!(await withinRateLimit(request, env))) {
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
