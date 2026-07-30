# SafeTJ

SafeTJ is a disaster-management and emergency-reporting platform for the Republic
of Tajikistan. Citizens report natural disasters in real time from a mobile app;
government authorities monitor and respond from a live web dashboard.

## Repository layout

```
backend/   Laravel 11 REST API + PostGIS-backed geo data + Blade admin dashboard
mobile/    Flutter citizen app (clean architecture, Riverpod, go_router)
docs/      Shared API contract used by both backend and mobile
```

Start with [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md) — it's the single source
of truth for every endpoint, JSON shape, and enum shared between the two apps.

## Citizen app (`mobile/`)

- Phone number registration/login via Firebase Authentication.
- One-tap emergency reporting: Flood, Landslide, Earthquake, Fire, Avalanche, Other.
- Reports capture GPS location, photos/videos, description, injured count, and
  road-blocked status.
- Offline-first: reports queue locally (Hive) and sync automatically once
  connectivity returns.
- Push notifications (Firebase Cloud Messaging) for nearby emergency alerts.
- Interactive map (OpenStreetMap via flutter_map) of nearby incidents.
- Emergency phone numbers and nearby shelters/hospitals/police/emergency centers.
- Tajik, Russian, and English localization; light and dark themes in the
  Tajikistan flag palette (blue/white/red).

See [`mobile/README.md`](mobile/README.md) for setup and architecture details.

## Government dashboard & API (`backend/`)

- Laravel 11 REST API (`/api/v1/...`) consumed by the mobile app, authenticated
  with Firebase ID tokens exchanged for Sanctum tokens.
- PostgreSQL + PostGIS for geospatial incident/shelter queries (nearby search,
  province/district filtering).
- Server-rendered admin dashboard (`/admin/...`) with session auth: live map of
  all incidents, filters by type/district/province, media review, status
  workflow (New → Verified → Rescue Team Dispatched → Resolved), and a
  statistics view (totals, active/resolved counts, breakdowns by region and
  disaster type).
- FCM topic notifications on incident verification and admin broadcasts.

See [`backend/README.md`](backend/README.md) for setup, environment
configuration, and the full endpoint list.

## Status

This repository currently contains the initial architecture and scaffolding for
both apps: database schema, models, API/admin controllers and views on the
backend; app shell, routing, theming, localization, offline sync, and all
feature screens on the mobile side. Package installation (`composer install`,
`flutter pub get`) and integration testing against a live PostgreSQL/PostGIS
instance and Firebase project still need to be done in an environment with
those tools available.
