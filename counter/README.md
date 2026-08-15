# Burn My Desire — world counter

The anonymous aggregate behind the website's "€X burned" headline.
A Cloudflare Worker with a D1 database behind it.

## What it stores

Two integers: a running total in cents, and a contributor count. There is
no user table, no install id, no IP log, and no per-contribution
timestamp. The app sends the *delta* since its last contribution, so the
server never needs to know who sent what — and a breach here would leak
a number that is already published.

## Endpoints

| Method | Path                 | Purpose                                    |
| ------ | -------------------- | ------------------------------------------ |
| GET    | `/api/stats`         | `{ totalCents, contributors, updatedAt }`   |
| POST   | `/api/contributions` | `{ deltaCents, firstTime }` → updated stats |

Contributions are rate limited to ten a minute per address, via the
Workers rate-limiting binding — the key is handed over per request and
never stored. Each contribution is capped at €1,000,000, so one absurd
submission can't permanently distort a public figure.

There is no `/health`: Cloudflare has no container to probe.

## Layout

    src/validate.js   the rules, with no database in sight
    src/store.js      the two D1 queries
    src/index.js      routing, CORS, rate limiting
    migrations/       the schema, applied by wrangler

The split exists so the interesting logic stays testable without a
Worker running.

## First deploy

```bash
npm install
npx wrangler d1 create burnmydesire-counter   # prints a database_id
```

Paste that id into `wrangler.jsonc` (it replaces `PLACEHOLDER_RUN_D1_CREATE`),
then:

```bash
npm run migrate     # applies migrations/ to the remote database
npm run deploy
```

Point `counter.burnmydesire.com` at **this** Worker, not the website one —
a custom domain is only an address, and attaching it to the site Worker
serves the site's HTML on `/api/stats`.

Finally, build the app with the URL compiled in, or the counter UI stays
hidden by design:

```bash
flutter build ios --release --dart-define=COUNTER_URL=https://counter.burnmydesire.com
```

## Tests

```bash
npm test
```

`node --test` covers the pure rules; `vitest` runs the Worker against a
real local D1, migrated from the same files production uses. The rate
limiter is live in those tests, so a case that reuses a key across tests
will starve — pass a distinct key per contribution.

## Honesty note

The total is self-reported by users who opted in, and unverifiable. The
website must label it that way; inflating it is the one thing that would
break trust in a privacy-first product.
