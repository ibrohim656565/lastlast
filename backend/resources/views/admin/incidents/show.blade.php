@extends('layouts.admin')

@section('title', 'Incident #' . $incident->id)

@section('content')
    <p><a href="{{ route('admin.incidents.index') }}">&larr; Back to incidents</a></p>

    @if ($errors->any())
        <div class="error-text" style="margin-bottom:1rem;">{{ $errors->first() }}</div>
    @endif

    <div class="card">
        <div style="display:flex; justify-content:space-between; align-items:center;">
            <h2 style="margin:0;">Incident #{{ $incident->id }} — {{ ucfirst($incident->type) }}</h2>
            <span class="badge badge-{{ $incident->status }}">{{ $incident->status }}</span>
        </div>

        <div class="detail-grid">
            <div class="item">
                <div class="label">Reporter</div>
                <div class="value">{{ $incident->reporter?->name ?? 'Anonymous' }} ({{ \App\Support\PhoneMasker::mask($incident->reporter?->phone) ?? '—' }})</div>
            </div>
            <div class="item">
                <div class="label">Province / District</div>
                <div class="value">{{ $incident->province?->name_en ?? '—' }} / {{ $incident->district?->name_en ?? '—' }}</div>
            </div>
            <div class="item">
                <div class="label">Location</div>
                <div class="value">{{ number_format((float) $incident->lat, 5) }}, {{ number_format((float) $incident->lng, 5) }}</div>
            </div>
            <div class="item">
                <div class="label">Injured</div>
                <div class="value">{{ $incident->injured_count }}</div>
            </div>
            <div class="item">
                <div class="label">Road blocked</div>
                <div class="value">{{ $incident->road_blocked ? 'Yes' : 'No' }}</div>
            </div>
            <div class="item">
                <div class="label">Reported at</div>
                <div class="value">{{ $incident->created_at->format('Y-m-d H:i') }}</div>
            </div>
            <div class="item">
                <div class="label">Verified at</div>
                <div class="value">{{ $incident->verified_at?->format('Y-m-d H:i') ?? '—' }}</div>
            </div>
            <div class="item">
                <div class="label">Dispatched at</div>
                <div class="value">{{ $incident->dispatched_at?->format('Y-m-d H:i') ?? '—' }}</div>
            </div>
            <div class="item">
                <div class="label">Resolved at</div>
                <div class="value">{{ $incident->resolved_at?->format('Y-m-d H:i') ?? '—' }}</div>
            </div>
        </div>

        <div class="item">
            <div class="label">Description</div>
            <div class="value">{{ $incident->description ?: '—' }}</div>
        </div>

        @if ($incident->media->isNotEmpty())
            <h3 style="font-size:0.9rem; text-transform:uppercase; color:var(--color-text-muted); margin-bottom:0.5rem;">Media</h3>
            <div class="media-gallery">
                @foreach ($incident->media as $media)
                    @if ($media->type === 'photo')
                        <img src="{{ \Illuminate\Support\Facades\Storage::disk('public')->url($media->path) }}" alt="Incident photo">
                    @else
                        <video src="{{ \Illuminate\Support\Facades\Storage::disk('public')->url($media->path) }}" controls></video>
                    @endif
                @endforeach
            </div>
        @endif

        @if (count($nextStatuses) > 1)
            <form method="POST" action="{{ route('admin.incidents.status', $incident) }}" class="status-form">
                @csrf
                @method('PATCH')
                <label for="status" style="font-size:0.85rem; color:var(--color-text-muted);">Change status:</label>
                <select name="status" id="status">
                    @foreach ($nextStatuses as $status)
                        <option value="{{ $status }}" @selected($status === $incident->status)>{{ ucfirst($status) }}</option>
                    @endforeach
                </select>
                <button type="submit" class="btn">Update</button>
            </form>
        @endif
    </div>
@endsection
