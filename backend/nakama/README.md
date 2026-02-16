# LumaRush Nakama Backend

This folder provides a local Nakama backend for LumaRush with:

- User authentication hooks (custom + device).
- Per-user high score tracking.
- Global high score leaderboard.
- Optional Terapixel platform integration webhooks.

## Files

- `backend/nakama/docker-compose.yml`: Local CockroachDB + Nakama stack.
- `backend/nakama/local.yml`: Nakama runtime config.
- `backend/nakama/modules/lumarush.js`: Runtime module with hooks and RPCs.

## Run Locally

1. `cd backend/nakama`
2. `docker compose up --build`

Nakama ports:

- API: `http://localhost:7350`
- Console: `http://localhost:7351` (`admin` / `adminpassword`)

## Runtime Environment Variables

Set these in `backend/nakama/local.yml` under `runtime.env`:

- `TPX_PLATFORM_AUTH_URL`: Optional URL called before custom/device auth. Non-2xx blocks auth.
- `TPX_PLATFORM_EVENT_URL`: Optional URL called on auth success and score submit.
- `TPX_PLATFORM_API_KEY`: Optional bearer token for both Terapixel endpoints.
- `TPX_HTTP_TIMEOUT_MS`: HTTP timeout for Terapixel calls (default `5000`).
- `LUMARUSH_LEADERBOARD_ID`: Leaderboard ID (default `lumarush_high_scores`).

## RPC Contract

### `tpx_submit_score`

Authenticated user only.

Request:

```json
{
  "score": 1000,
  "subscore": 12,
  "metadata": { "track": "neo_city" }
}
```

Response:

```json
{
  "leaderboardId": "lumarush_high_scores",
  "record": { "...": "nakama leaderboard record" }
}
```

### `tpx_get_my_high_score`

Authenticated user only.

Request: `{}` or empty payload.

Response:

```json
{
  "leaderboardId": "lumarush_high_scores",
  "highScore": { "...": "owner leaderboard record or null" },
  "playerStats": {
    "bestScore": 1000,
    "bestSubscore": 12,
    "rank": 5
  }
}
```

### `tpx_list_leaderboard`

Public list.

Request:

```json
{
  "limit": 25,
  "cursor": ""
}
```

Response:

```json
{
  "leaderboardId": "lumarush_high_scores",
  "records": [],
  "nextCursor": "",
  "prevCursor": "",
  "rankCount": 0
}
```

## Auth for Clients

Clients should authenticate with Nakama normally (device/custom). This module adds:

- Optional pre-auth verification against `TPX_PLATFORM_AUTH_URL`.
- Auth success event emission to `TPX_PLATFORM_EVENT_URL`.

If the Terapixel auth URL is unset, Nakama auth proceeds without external verification.

## Deploy on Render

This repo now includes a Render Blueprint at `render.yaml` for a managed Postgres database plus a Docker-based Nakama web service.

1. In Render, create a new Blueprint deployment from this repo.
2. Confirm the `lumarush-nakama` service and `lumarush-nakama-db` database are detected.
3. Set secrets that are marked `sync: false`:
   - `TPX_PLATFORM_AUTH_URL` (optional)
   - `TPX_PLATFORM_EVENT_URL` (optional)
   - `TPX_PLATFORM_API_KEY` (optional)
   - `NAKAMA_CONSOLE_PASSWORD` (recommended)
4. Deploy.

The Render startup script (`backend/nakama/render/start.sh`) runs migrations, starts Nakama on internal ports, and fronts it with nginx on Render's public `PORT`.

On Render:

- API/Client endpoints: `https://<your-service>.onrender.com/`
- Console: `https://<your-service>.onrender.com/console/`
