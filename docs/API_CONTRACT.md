# SafeTJ API Contract

This is the single source of truth both the Flutter app (`mobile/`) and the Laravel
backend (`backend/`) must implement against. Keep it in sync if the shape changes.

## Conventions

- Base URL (mobile JSON API): `/api/v1`
- Admin web dashboard (Blade, session auth): `/admin`
- All JSON responses: `{ "data": ..., "message": "...", "errors": {...} }` (Laravel default resource/validation shape)
- Auth: citizens authenticate with Firebase Phone Auth on-device, then exchange the
  Firebase ID token for a Laravel Sanctum token. Admin/dispatcher users log in with
  email+password on the web dashboard (session guard `web`), separate from the
  mobile API guard (`sanctum`).
- Dates: ISO 8601 UTC.
- Enums are lowercase snake_case strings.

## Enums

- `incident_type`: `flood | landslide | earthquake | fire | avalanche | other`
- `incident_status`: `new | verified | dispatched | resolved`
- `safe_point_type`: `shelter | hospital | police | emergency_center`
- `user_role`: `citizen | dispatcher | admin`
- `media_type`: `photo | video`
- `language`: `tg | ru | en`

## Reference data

`GET /api/v1/provinces` -> `[{id, name_tg, name_ru, name_en}]`
`GET /api/v1/districts?province_id=` -> `[{id, province_id, name_tg, name_ru, name_en}]`

Seeded provinces: Dushanbe, Sughd, Khatlon, DRS (RRP), GBAO — each with a handful of
real districts.

## Auth

`POST /api/v1/auth/login`
Request: `{ "firebase_id_token": "..." }`
Response: `{ "data": { "token": "sanctum-plain-text-token", "user": User } }`

`User` shape: `{ id, name, phone, preferred_language, role, created_at }`

`GET /api/v1/auth/me` (auth) -> `{ "data": User }`
`PUT /api/v1/auth/me` (auth) body `{ name?, preferred_language? }` -> `{ "data": User }`

## Device tokens (push)

`POST /api/v1/device-tokens` (auth) body `{ token, platform: "android"|"ios" }`
Registers/updates FCM token for the user; server subscribes it to
`province_{id}` and `district_{id}` topics based on the user's last known
report location (best-effort, optional fields `province_id`, `district_id` in body).

## Incidents

`GET /api/v1/incidents` (auth) query: `type, status, province_id, district_id, lat, lng, radius_km, from, to, page`
-> paginated `{ data: [Incident], meta: {...}, links: {...} }`

`POST /api/v1/incidents` (auth, multipart/form-data)
Fields: `client_uuid` (uuid v4, generated on-device for idempotent offline sync),
`type`, `description`, `injured_count` (int, default 0), `road_blocked` (bool),
`lat`, `lng`, `province_id?`, `district_id?`, `media[]` (files, photo/video, optional, max 5).
-> `{ "data": Incident }` (201). If `client_uuid` already exists for this user, returns
the existing incident with 200 instead of creating a duplicate.

`GET /api/v1/incidents/{id}` (auth) -> `{ "data": Incident }`

`POST /api/v1/incidents/sync` (auth, multipart/form-data, batched offline queue flush)
Accepts the same fields as create, but as an array `reports[]`, each with its own
`client_uuid` and `media[]`. -> `{ "data": [{ client_uuid, status: "created"|"duplicate"|"error", incident?, error? }] }`

`Incident` shape:
```json
{
  "id": 1,
  "client_uuid": "uuid",
  "type": "flood",
  "status": "new",
  "description": "...",
  "injured_count": 0,
  "road_blocked": false,
  "location": { "lat": 38.5598, "lng": 68.7870 },
  "province": { "id": 1, "name_en": "Dushanbe" },
  "district": { "id": 1, "name_en": "..." },
  "media": [{ "id": 1, "type": "photo", "url": "...", "thumbnail_url": "..." }],
  "reporter": { "id": 5, "name": "...", "phone_masked": "+992 9* *** **12" },
  "created_at": "...",
  "verified_at": null,
  "dispatched_at": null,
  "resolved_at": null
}
```

Admin-only:
`PATCH /admin/incidents/{id}/status` body `{ status }` — validated forward-only
transitions `new -> verified -> dispatched -> resolved` (admin can also jump ahead,
never backward, except super-admin). Triggers FCM push to nearby subscribers on
`verified`.

## Safe points (shelters / hospitals / police / emergency centers)

`GET /api/v1/safe-points?type=&lat=&lng=&radius_km=` (auth) -> `[SafePoint]`
sorted by distance when `lat/lng` given.

`SafePoint`: `{ id, type, name, phone, location: {lat,lng}, province_id, district_id, address }`

## Emergency contacts

`GET /api/v1/emergency-contacts?category=` (public) -> `[{ id, category, name, phone }]`
Categories: `police, ambulance, fire, gas, rescue_service, other`.

## Admin dashboard (server-rendered, session auth, blue/white/red gov theme)

- `GET/POST /admin/login`, `POST /admin/logout`
- `GET /admin/dashboard` — stat cards (total, active, resolved, by region, by type) + live map
- `GET /admin/incidents` — filterable table (type, district, province, status, date range) + map
- `GET /admin/incidents/{id}` — detail, media gallery, status changer
- `GET /admin/api/stats.json` — ajax data source for dashboard charts
- `GET /admin/api/incidents.json` — ajax data source for the live map (same filters as the table)

## Notifications

When an incident transitions to `verified`, or an admin broadcasts a manual alert,
the backend publishes to FCM topics `province_{id}` / `district_{id}` (and
`all_tj` for nationwide alerts). Payload:
```json
{ "title": "...", "body": "...", "data": { "type": "incident_verified", "incident_id": "1" } }
```
