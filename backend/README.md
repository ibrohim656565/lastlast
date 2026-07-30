# SafeTJ Backend

Laravel 11 API + admin dashboard for SafeTJ, the disaster-management and
emergency-reporting platform for the Republic of Tajikistan. The mobile app
(`../mobile/`) and this backend both implement
[`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) — treat it as the single
source of truth for routes, JSON shapes, and enums.

## Stack

- PHP 8.2+, Laravel 11
- PostgreSQL + [PostGIS](https://postgis.net/) (incident/safe-point locations
  are `geography(Point, 4326)` columns, queried with `ST_DWithin`/`ST_Distance`)
- Laravel Sanctum (mobile API bearer tokens)
- [kreait/laravel-firebase](https://github.com/kreait/laravel-firebase)
  (verifying Firebase Phone Auth ID tokens on login, sending FCM push)
- Server-rendered Blade admin dashboard (Leaflet.js + Chart.js via CDN, no
  JS build step)

## Setup

```bash
composer install

cp .env.example .env
php artisan key:generate
```

### Database

Create a PostgreSQL database and enable PostGIS once (a superuser or a role
with `CREATE` privilege is required for the extension itself; the migration
`2024_01_02_000000_enable_postgis_extension.php` also attempts this, but
pre-creating it avoids permission issues in managed Postgres):

```sql
CREATE DATABASE safetj;
\c safetj
CREATE EXTENSION IF NOT EXISTS postgis;
```

Set in `.env`:

```
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=safetj
DB_USERNAME=safetj
DB_PASSWORD=your-password
```

### Firebase

1. In the Firebase console, create/select the project used by the mobile
   app's Phone Auth flow.
2. Project Settings → Service Accounts → Generate new private key. Save the
   JSON somewhere **outside** version control, e.g.
   `storage/app/firebase-credentials.json` (already gitignored).
3. Set in `.env`:

```
FIREBASE_CREDENTIALS=storage/app/firebase-credentials.json
FIREBASE_PROJECT_ID=your-firebase-project-id
```

This same service account is used both to verify ID tokens on
`POST /api/v1/auth/login` and to publish FCM pushes (`NotificationService`).

### Migrate, seed, run

```bash
php artisan storage:link
php artisan migrate --seed
php artisan serve
```

Seeded data:

- Reference geography: 5 provinces (Dushanbe, Sughd, Khatlon, DRS/RRP, GBAO)
  with a handful of real districts each (`ProvinceSeeder`, `DistrictSeeder`).
- Emergency numbers: Fire 101, Police 102, Ambulance 103, Gas 104, Unified
  Rescue Service 112 (`EmergencyContactSeeder`) — standard nationwide
  short numbers, not invented.
- One admin dashboard login (`AdminUserSeeder`): email/password come from
  `ADMIN_SEED_EMAIL` / `ADMIN_SEED_PASSWORD` in `.env` (defaults in
  `.env.example` are local-dev placeholders — **change both before any real
  deployment**).

The admin dashboard is at `/admin/login`; the mobile JSON API is under
`/api/v1`.

## Notes on things that couldn't be verified in this environment

This repository was written without network/composer-registry access, so
`vendor/` was never installed and `php artisan migrate` etc. were never
actually run against a live PostGIS database. Every PHP file passes `php -l`
(no syntax errors), and the code follows the standard Laravel 11
"new-style" bootstrap (`bootstrap/app.php`), but end-to-end behavior
(migrations against real PostGIS, Sanctum token issuance, Firebase
verification, FCM delivery) has not been executed. Run
`composer install && php artisan migrate --seed` in an environment with
network access and a real Postgres+PostGIS instance before deploying.

## Endpoint overview

See [`../docs/API_CONTRACT.md`](../docs/API_CONTRACT.md) for exact request/response
shapes. Summary:

**Mobile API (`/api/v1`, Sanctum bearer auth unless noted)**

| Method | Path | Notes |
|---|---|---|
| GET | `/provinces` | public |
| GET | `/districts?province_id=` | public |
| GET | `/emergency-contacts?category=` | public |
| POST | `/auth/login` | public — exchanges a Firebase ID token for a Sanctum token |
| GET/PUT | `/auth/me` | auth |
| POST | `/device-tokens` | auth — registers an FCM token, best-effort topic subscribe |
| GET | `/incidents` | auth — filterable, paginated |
| POST | `/incidents` | auth, multipart — idempotent on `client_uuid` per reporter |
| GET | `/incidents/{id}` | auth |
| POST | `/incidents/sync` | auth, multipart — batched offline-queue flush |
| GET | `/safe-points?type=&lat=&lng=&radius_km=` | auth |

**Admin dashboard (`/admin`, session auth, role `admin`/`dispatcher`)**

| Method | Path | Notes |
|---|---|---|
| GET/POST | `/login` | |
| POST | `/logout` | |
| GET | `/dashboard` | stat cards + live Leaflet map |
| GET | `/incidents` | filterable table + map |
| GET | `/incidents/{id}` | detail, media gallery, status changer |
| PATCH | `/incidents/{id}/status` | forward-only `new → verified → dispatched → resolved`; `admin` role may also jump backward, `dispatcher` may not |
| GET | `/api/stats.json` | dashboard chart data source |
| GET | `/api/incidents.json` | live map data source (same filters as the table) |

## Notable implementation choices / deviations

- **PostGIS via raw SQL**: `incidents.location` and `safe_points.location`
  are added with `DB::statement('ALTER TABLE ... ADD COLUMN location
  geography(Point, 4326) ...')` since Eloquent's schema builder has no
  native geography type. Reads go through a global Eloquent scope that
  `ST_Y`/`ST_X`-projects the column into plain `lat`/`lng` floats on every
  query; writes go through `Incident::setPoint()` /
  `SafePoint::setPoint()`, which issue a parameterised
  `UPDATE ... SET location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography`
  (safe from injection — floats are bound, not interpolated).
- **`client_uuid` uniqueness** is scoped to `(reporter_id, client_uuid)`,
  matching the contract's "unique per reporter" wording and the sync
  endpoint's stated dedupe key.
- **Video thumbnails**: `IncidentMedia.thumbnail_path` is always `null` for
  videos right now — real thumbnailing needs `ffmpeg`, which isn't
  available in this environment. See the `TODO` in
  `IncidentController::storeMediaFile()`.
- **`phone_masked`**: `App\Support\PhoneMasker` special-cases the standard
  Tajik `+992` / 9-digit mobile format (revealing the first digit and last
  two digits, e.g. `+992 9* *** **12`) and falls back to a generic
  first-2/last-2-digit mask for anything else.
- **Forward-only status transitions**: enforced in
  `Admin\IncidentController@updateStatus`. The contract mentions a
  "super-admin" exception for backward moves; this codebase has no separate
  super-admin role yet, so `role = admin` is treated as that exception and
  `role = dispatcher` stays strictly forward-only — noted in a comment at
  `IncidentController::isSuperAdmin()`.
- **`GET /api/v1/incidents`** is not scoped to the caller's own reports —
  any authenticated citizen can see the shared incident feed (needed for
  situational awareness), matching the absence of a reporter filter in the
  contract's query parameter list.
