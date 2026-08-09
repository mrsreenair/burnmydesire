import { createServer } from 'node:http';

import { RateLimiter } from './rate_limit.js';
import { addContribution, openStore, readStats } from './store.js';

const PORT = Number(process.env.PORT ?? 8080);
const DB_FILE = process.env.DB_FILE ?? '/data/counter.sqlite';
/** Comma-separated origins allowed to read the stats, or * for any. */
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS ?? '*')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

const db = openStore(DB_FILE);
const limiter = new RateLimiter({
  limit: Number(process.env.RATE_LIMIT ?? 10),
  windowMs: Number(process.env.RATE_WINDOW_MS ?? 60_000),
});

function corsHeaders(origin) {
  const allow =
    ALLOWED_ORIGINS.includes('*') || (origin && ALLOWED_ORIGINS.includes(origin))
      ? origin || '*'
      : ALLOWED_ORIGINS[0];
  return {
    'access-control-allow-origin': allow,
    'access-control-allow-methods': 'GET,POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
    'access-control-max-age': '86400',
  };
}

function send(res, status, body, origin) {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    ...corsHeaders(origin),
  });
  res.end(payload);
}

/** Behind Coolify/Dokploy there's a proxy, so honour the forwarded header. */
function clientAddress(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.socket.remoteAddress ?? 'unknown';
}

async function readJson(req, limitBytes = 1024) {
  let size = 0;
  const chunks = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limitBytes) throw new Error('body too large');
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

export const server = createServer(async (req, res) => {
  const origin = req.headers.origin;
  const url = new URL(req.url ?? '/', 'http://localhost');

  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders(origin));
    res.end();
    return;
  }

  if (req.method === 'GET' && url.pathname === '/health') {
    send(res, 200, { ok: true }, origin);
    return;
  }

  if (req.method === 'GET' && url.pathname === '/api/stats') {
    send(res, 200, readStats(db), origin);
    return;
  }

  if (req.method === 'POST' && url.pathname === '/api/contributions') {
    if (!limiter.allow(clientAddress(req))) {
      send(res, 429, { error: 'too many requests' }, origin);
      return;
    }
    let body;
    try {
      body = await readJson(req);
    } catch {
      send(res, 400, { error: 'invalid body' }, origin);
      return;
    }
    const result = addContribution(db, {
      deltaCents: body.deltaCents,
      firstTime: body.firstTime === true,
    });
    if (!result.ok) {
      send(res, 400, { error: result.reason }, origin);
      return;
    }
    send(res, 200, readStats(db), origin);
    return;
  }

  send(res, 404, { error: 'not found' }, origin);
});

// Not started when imported by tests.
if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    console.log(`counter listening on ${PORT}, db ${DB_FILE}`);
  });
}
