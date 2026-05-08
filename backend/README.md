# Lumina Ephemeris Backend

Self-hosted Fastify microservice that returns a `NatalChart` for a given
`BirthData`. Talks to the iOS `EphemerisService` actor over HTTP+JSON with
a shared-secret header.

## Stack

- Fastify 5 + TypeScript 5 (NodeNext, ESM, `verbatimModuleSyntax`,
  `allowImportingTsExtensions` — runs as `.ts` directly via Node 22's
  `--experimental-strip-types`, no bundler in the loop)
- `astronomy-engine` for planet positions (pure JS, no native build tools).
  Will swap to `swisseph` once the Swiss Ephemeris Pro license clears —
  see `src/services/ephemeris.ts` interface seam.
- `zod` for request validation; the `BirthData` / `NatalChart` schemas
  mirror the Swift DTOs at `Lumina/Core/Ephemeris/Models/`.
- `vitest` for tests; no separate dev runner — `node --watch
  --experimental-strip-types` handles dev / start / CLI uniformly.

## Quick start

```bash
nvm use                                    # Node 22 LTS
cp .env.example .env
echo "LUMINA_API_SECRET=$(openssl rand -hex 32)" >> .env
npm install
npm run dev                                # http://127.0.0.1:3001
```

Smoke test:

```bash
curl http://127.0.0.1:3001/health
# {"status":"ok"}

curl -X POST http://127.0.0.1:3001/chart \
  -H "Content-Type: application/json" \
  -H "X-Lumina-Secret: $(grep LUMINA_API_SECRET .env | cut -d= -f2)" \
  -d '{
    "birthDate": "1990-06-15T00:00:00Z",
    "birthTime": "1990-06-15T14:30:00+02:00",
    "placeName": "Stockholm, Sweden",
    "latitude": 59.3293,
    "longitude": 18.0686,
    "timeZoneIdentifier": "Europe/Stockholm"
  }' | jq
```

## CLI (used by the `/chart` slash command)

```bash
npm run chart -- --date 1990-06-15 --time 14:30 --tz Europe/Stockholm
```

Pipes the same chart JSON to stdout — no server needed.

## Tests

```bash
npm test          # one-shot
npm run test:watch
```

Tests inject HTTP requests via `app.inject`, no real port binding.

## What's intentionally **not** here yet

- Houses (Placidus / Whole Sign / Sidereal) — next iteration
- Aspects, transits, progressions
- Production deploy (Fly.io setup, Dockerfile, healthcheck wiring)
- Caching (Redis or in-memory LRU for repeat birth-data queries)
- Rate limiting
- OpenTelemetry / Sentry instrumentation
- Swiss Ephemeris precision — gated on Swiss Eph Pro license (CHF 1,550,
  see TASK.md Blockers)

## Contract with the iOS client

The Swift side at `Lumina/Core/Ephemeris/EphemerisService.swift` POSTs to
`{SWISS_EPH_SERVICE_URL}/chart` with the body shape declared in
`src/types.ts` (`BirthDataSchema`). Header: `X-Lumina-Secret:
{SWISS_EPH_API_SECRET}`. Response is the `NatalChart` shape — array of
ten planet positions in J2000 ecliptic coordinates plus a placeholder
`houseSystem` until houses ship.
