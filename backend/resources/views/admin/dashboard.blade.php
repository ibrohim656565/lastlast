@extends('layouts.admin')

@section('title', 'Dashboard')

@push('head')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
          integrity="sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=" crossorigin="">
@endpush

@section('content')
    <div class="stat-grid">
        <div class="stat-card primary">
            <div class="label">Total incidents</div>
            <div class="value" id="stat-total">—</div>
        </div>
        <div class="stat-card accent">
            <div class="label">Active</div>
            <div class="value" id="stat-active">—</div>
        </div>
        <div class="stat-card success">
            <div class="label">Resolved</div>
            <div class="value" id="stat-resolved">—</div>
        </div>
    </div>

    <div class="card">
        <h2 style="margin-top:0; font-size:1rem;">Live incident map</h2>
        <div id="map"></div>
    </div>

    <div class="grid-charts">
        <div class="card">
            <h2 style="margin-top:0; font-size:1rem;">By region</h2>
            <canvas id="chart-region" height="220"></canvas>
        </div>
        <div class="card">
            <h2 style="margin-top:0; font-size:1rem;">By type</h2>
            <canvas id="chart-type" height="220"></canvas>
        </div>
    </div>
@endsection

@push('scripts')
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
            integrity="sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=" crossorigin=""></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <script>
        const STATUS_COLORS = { new: '#b8860b', verified: '#0033a0', dispatched: '#7c3aed', resolved: '#1a8f4c' };

        const map = L.map('map').setView([38.5598, 68.7870], 6); // Dushanbe
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '&copy; OpenStreetMap contributors',
            maxZoom: 18,
        }).addTo(map);

        const markersLayer = L.layerGroup().addTo(map);

        function loadIncidentsMap() {
            fetch('{{ route('admin.api.incidents') }}')
                .then((r) => r.json())
                .then((json) => {
                    markersLayer.clearLayers();
                    (json.data || []).forEach((incident) => {
                        if (incident.lat == null || incident.lng == null) return;
                        L.circleMarker([incident.lat, incident.lng], {
                            radius: 7,
                            color: STATUS_COLORS[incident.status] || '#0033a0',
                            fillColor: STATUS_COLORS[incident.status] || '#0033a0',
                            fillOpacity: 0.75,
                        })
                            .bindPopup(`<strong>${incident.type}</strong><br>${incident.status}<br><a href="/admin/incidents/${incident.id}">View #${incident.id}</a>`)
                            .addTo(markersLayer);
                    });
                });
        }

        function loadStats() {
            fetch('{{ route('admin.api.stats') }}')
                .then((r) => r.json())
                .then((json) => {
                    const stats = json.data;
                    document.getElementById('stat-total').textContent = stats.total;
                    document.getElementById('stat-active').textContent = stats.active;
                    document.getElementById('stat-resolved').textContent = stats.resolved;

                    new Chart(document.getElementById('chart-region'), {
                        type: 'bar',
                        data: {
                            labels: stats.by_region.map((r) => r.name_en),
                            datasets: [{ label: 'Incidents', data: stats.by_region.map((r) => r.total), backgroundColor: '#0033a0' }],
                        },
                        options: { plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true } } },
                    });

                    new Chart(document.getElementById('chart-type'), {
                        type: 'doughnut',
                        data: {
                            labels: stats.by_type.map((t) => t.type),
                            datasets: [{
                                data: stats.by_type.map((t) => t.total),
                                backgroundColor: ['#0033a0', '#ce1126', '#1a8f4c', '#b8860b', '#7c3aed', '#5b6478'],
                            }],
                        },
                    });
                });
        }

        loadIncidentsMap();
        loadStats();
    </script>
@endpush
