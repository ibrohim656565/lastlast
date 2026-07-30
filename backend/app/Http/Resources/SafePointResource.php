<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\SafePoint
 */
class SafePointResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'name' => $this->name,
            'phone' => $this->phone,
            'location' => [
                'lat' => (float) $this->lat,
                'lng' => (float) $this->lng,
            ],
            'province_id' => $this->province_id,
            'district_id' => $this->district_id,
            'address' => $this->address,
        ];
    }
}
