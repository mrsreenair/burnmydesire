# Burn My Desire — world counter

The anonymous aggregate behind the website's "€X burned" headline.

## What it stores

Two integers: a running total in cents, and a contributor count. There is
no user table, no install id, no IP log, and no per-contribution
timestamp. The app sends the *delta* since its last contribution, so the
server never needs to know who sent what — and a breach here would leak
a number that is already published.

## Endpoints

| Method | Path                 | Purpose                                    |
| ------ | -------------------- | ------------------------------------------ |
| GET    | `/health`            | Container health check                      |
| GET    | `/api/stats`         | `{ totalCents, contributors, updatedAt }`   |
| POST   | `/api/contributions` | `{ deltaCents, firstTime }` → updated stats |

Contributions are rate limited per client (hashed with a per-process salt
that dies with the process) and capped at €1,000,000 each, so one absurd
submission can't permanently distort a public figure.

## Deploying (Coolify / Dokploy on Hetzner)

1. New resource → **Docker Compose**, point at this repo, set the base
   directory to `counter/`.
2. Set `ALLOWED_ORIGINS` to the site origin (e.g. `https://burnmydesire.com`).
   Leave `*` only while testing.
3. Attach a persistent volume at `/data` — Compose already declares it.
4. Point the app and website at the resulting URL.

## Local

```bash
npm install
npm test
DB_FILE=./counter.sqlite npm start
```

## Honesty note

The total is self-reported by users who opted in, and unverifiable. The
website must label it that way; inflating it is the one thing that would
break trust in a privacy-first product.
