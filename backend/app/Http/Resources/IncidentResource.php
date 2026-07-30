<?php

namespace App\Http\Resources;

use App\Support\PhoneMasker;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Incident
 */
class IncidentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'client_uuid' => $this->client_uuid,
            'type' => $this->type,
            'status' => $this->status,
            'description' => $this->description,
            'injured_count' => $this->injured_count,
            'road_blocked' => $this->road_blocked,
            'location' => [
                'lat' => $this->lat !== null ? (float) $this->lat : null,
                'lng' => $this->lng !== null ? (float) $this->lng : null,
            ],
            'province' => $this->whenLoaded('province', fn () => $this->province ? [
                'id' => $this->province->id,
                'name_en' => $this->province->name_en,
            ] : null),
            'district' => $this->whenLoaded('district', fn () => $this->district ? [
                'id' => $this->district->id,
                'name_en' => $this->district->name_en,
            ] : null),
            'media' => IncidentMediaResource::collection($this->whenLoaded('media')),
            'reporter' => $this->whenLoaded('reporter', fn () => [
                'id' => $this->reporter->id,
                'name' => $this->reporter->name,
                'phone_masked' => PhoneMasker::mask($this->reporter->phone),
            ]),
            'created_at' => $this->created_at?->toISOString(),
            'verified_at' => $this->verified_at?->toISOString(),
            'dispatched_at' => $this->dispatched_at?->toISOString(),
            'resolved_at' => $this->resolved_at?->toISOString(),
        ];
    }
}
