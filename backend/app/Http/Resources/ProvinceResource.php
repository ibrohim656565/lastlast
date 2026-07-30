<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin \App\Models\Province
 */
class ProvinceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name_tg' => $this->name_tg,
            'name_ru' => $this->name_ru,
            'name_en' => $this->name_en,
        ];
    }
}
