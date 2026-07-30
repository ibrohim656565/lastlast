<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\IndexIncidentsRequest;
use App\Http\Requests\Api\StoreIncidentRequest;
use App\Http\Requests\Api\SyncIncidentsRequest;
use App\Http\Resources\IncidentResource;
use App\Models\Incident;
use App\Models\IncidentMedia;
use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Throwable;

class IncidentController extends Controller
{
    public function index(IndexIncidentsRequest $request)
    {
        $filters = $request->validated();

        $incidents = Incident::query()
            ->with(['province', 'district', 'media', 'reporter'])
            ->ofType($filters['type'] ?? null)
            ->ofStatus($filters['status'] ?? null)
            ->inProvince($filters['province_id'] ?? null)
            ->inDistrict($filters['district_id'] ?? null)
            ->reportedBetween($filters['from'] ?? null, $filters['to'] ?? null)
            ->when(
                isset($filters['lat'], $filters['lng']),
                fn ($q) => $q->nearby($filters['lat'], $filters['lng'], $filters['radius_km'] ?? 50),
                fn ($q) => $q->latest()
            )
            ->paginate(20)
            ->withQueryString();

        return IncidentResource::collection($incidents);
    }

    public function store(StoreIncidentRequest $request)
    {
        $user = $request->user();
        $data = $request->validated();

        $existing = Incident::query()
            ->where('reporter_id', $user->id)
            ->where('client_uuid', $data['client_uuid'])
            ->first();

        if ($existing) {
            $existing->load(['province', 'district', 'media', 'reporter']);

            return (new IncidentResource($existing))
                ->response()
                ->setStatusCode(200);
        }

        $incident = $this->createIncident($user, $data, $request->file('media', []));

        return (new IncidentResource($incident))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Incident $incident)
    {
        $incident->load(['province', 'district', 'media', 'reporter']);

        return response()->json([
            'data' => new IncidentResource($incident),
        ]);
    }

    public function sync(SyncIncidentsRequest $request)
    {
        $user = $request->user();
        $reports = $request->input('reports', []);
        $results = [];

        foreach ($reports as $index => $reportData) {
            $clientUuid = $reportData['client_uuid'] ?? null;

            try {
                $validator = Validator::make($reportData, StoreIncidentRequest::fieldRules());
                $validator->validate();
                $validated = $validator->validated();

                $existing = Incident::query()
                    ->where('reporter_id', $user->id)
                    ->where('client_uuid', $validated['client_uuid'])
                    ->first();

                if ($existing) {
                    $existing->load(['province', 'district', 'media', 'reporter']);

                    $results[] = [
                        'client_uuid' => $validated['client_uuid'],
                        'status' => 'duplicate',
                        'incident' => new IncidentResource($existing),
                    ];

                    continue;
                }

                $mediaFiles = $request->file("reports.{$index}.media", []);

                $incident = $this->createIncident($user, $validated, $mediaFiles);

                $results[] = [
                    'client_uuid' => $validated['client_uuid'],
                    'status' => 'created',
                    'incident' => new IncidentResource($incident),
                ];
            } catch (Throwable $e) {
                // One bad report must never fail the rest of the offline
                // queue flush (API_CONTRACT.md).
                $results[] = [
                    'client_uuid' => $clientUuid,
                    'status' => 'error',
                    'error' => $e->getMessage(),
                ];
            }
        }

        return response()->json(['data' => $results]);
    }

    /**
     * @param  UploadedFile[]  $mediaFiles
     */
    private function createIncident(User $user, array $data, array $mediaFiles): Incident
    {
        return DB::transaction(function () use ($user, $data, $mediaFiles) {
            $incident = Incident::create([
                'client_uuid' => $data['client_uuid'],
                'type' => $data['type'],
                'status' => 'new',
                'description' => $data['description'] ?? null,
                'injured_count' => $data['injured_count'] ?? 0,
                'road_blocked' => $data['road_blocked'] ?? false,
                'province_id' => $data['province_id'] ?? null,
                'district_id' => $data['district_id'] ?? null,
                'reporter_id' => $user->id,
            ]);

            $incident->setPoint((float) $data['lat'], (float) $data['lng']);

            foreach ($mediaFiles as $file) {
                if (! $file instanceof UploadedFile || ! $file->isValid()) {
                    continue;
                }

                $this->storeMediaFile($incident, $file);
            }

            $incident->load(['province', 'district', 'media', 'reporter']);

            return $incident;
        });
    }

    private function storeMediaFile(Incident $incident, UploadedFile $file): void
    {
        $isVideo = str_starts_with((string) $file->getMimeType(), 'video/');
        $type = $isVideo ? 'video' : 'photo';

        $filename = Str::uuid()->toString().'.'.$file->getClientOriginalExtension();
        $path = $file->storeAs("incidents/{$incident->id}", $filename, 'public');

        // TODO: real video thumbnailing needs ffmpeg (not available in this
        // environment). For now videos ship without a thumbnail and the
        // mobile client falls back to a generic video placeholder icon.
        $thumbnailPath = null;

        IncidentMedia::create([
            'incident_id' => $incident->id,
            'type' => $type,
            'path' => $path,
            'thumbnail_path' => $thumbnailPath,
        ]);
    }
}
