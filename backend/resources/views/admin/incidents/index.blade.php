@extends('layouts.admin')

@section('title', 'Incidents')

@push('head')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
@endpush

@section('content')
    <div class="grid-2">
        <div>
            <form method="GET" class="filters card" style="margin-bottom:1.25rem;">
                <select name="type">
                    <option value="">All types</option>
                    @foreach (['flood', 'landslide', 'earthquake', 'fire', 'avalanche', 'other'] as $type)
                        <option value="{{ $type }}" @selected(($filters['type'] ?? '') === $type)>{{ ucfirst($type) }}</option>
                    @endforeach
                </select>

                <select name="status">
                    <option value="">All statuses</option>
                    @foreach (['new', 'verified', 'dispatched', 'resolved'] as $status)
                        <option value="{{ $status }}" @selected(($filters['status'] ?? '') === $status)>{{ ucfirst($status) }}</option>
                    @endforeach
                </select>

                <select name="province_id">
                    <option value="">All provinces</option>
                    @foreach ($provinces as $province)
                        <option value="{{ $province->id }}" @selected((string) ($filters['province_id'] ?? '') === (string) $province->id)>{{ $province->name_en }}</option>
                    @endforeach
                </select>

                <select name="district_id">
                    <option value="">All districts</option>
                    @foreach ($districts as $district)
                        <option value="{{ $district->id }}" @selected((string) ($filters['district_id'] ?? '') === (string) $district->id)>{{ $district->name_en }}</option>
                    @endforeach
                </select>

                <input type="date" name="from" value="{{ $filters['from'] ?? '' }}" placeholder="From">
                <input type="date" name="to" value="{{ $filters['to'] ?? '' }}" placeholder="To">

                <button type="submit" class="btn">Filter</button>
                <a href="{{ route('admin.incidents.index') }}" class="btn" style="background:var(--color-surface-alt); color:var(--color-text);">Reset</a>
            </form>

            <div class="card">
                <div style="overflow-x:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Type</th>
                                <th>Status</th>
                                <th>Province</th>
                                <th>District</th>
                                <th>Reporter</th>
                                <th>Reported</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($incidents as $incident)
                                <tr>
                                    <td><a href="{{ route('admin.incidents.show', $incident) }}">#{{ $incident->id }}</a></td>
                                    <td>{{ ucfirst($incident->type) }}</td>
                                    <td><span class="badge badge-{{ $incident->status }}">{{ $incident->status }}</span></td>
                                    <td>{{ $incident->province?->name_en ?? '—' }}</td>
                                    <td>{{ $incident->district?->name_en ?? '—' }}</td>
                                    <td>{{ $incident->reporter?->name ?? 'Anonymous' }}</td>
                                    <td>{{ $incident->created_at->format('Y-m-d H:i') }}</td>
                                </tr>
                            @empty
                                <tr><td colspan="7" style="text-align:center; color:var(--color-text-muted);">No incidents match these filters.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
                <div style="margin-top:1rem;">{{ $incidents->links() }}</div>
            </div>
        </div>

        <div class="card map-small">
            <h2 style="margin-top:0; font-size:1rem;">Map</h2>
            <div id="incidents-map"></div>
        </div>
    </div>
@endsection

@push('scripts')
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
            integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <script>
        const STATUS_COLORS = { new: '#b8860b', verified: '#0033a0', dispatched: '#7c3aed', resolved: '#1a8f4c' };
        const map = L.map('incidents-map').setView([38.5598, 68.7870], 6);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors',
            maxZoom: 18,
        }).addTo(map);

        const params = new URLSearchParams(window.location.search);
        fetch('{{ route('admin.api.incidents') }}?' + params.toString())
            .then((r) => r.json())
            .then((json) => {
                (json.data || []).forEach((incident) => {
                    if (incident.lat == null || incident.lng == null) return;
                    L.circleMarker([incident.lat, incident.lng], {
                        radius: 6,
                        color: STATUS_COLORS[incident.status] || '#0033a0',
                        fillColor: STATUS_COLORS[incident.status] || '#0033a0',
                        fillOpacity: 0.75,
                    })
                        .bindPopup(`<strong>${incident.type}</strong><br>${incident.status}<br><a href="/admin/incidents/${incident.id}">View #${incident.id}</a>`)
                        .addTo(map);
                });
            });
    </script>
@endpush
