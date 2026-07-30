<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreIncidentRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'client_uuid' => ['required', 'uuid'],
            'type' => ['required', 'in:flood,landslide,earthquake,fire,avalanche,other'],
            'description' => ['nullable', 'string'],
            'injured_count' => ['sometimes', 'integer', 'min:0'],
            'road_blocked' => ['sometimes', 'boolean'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'province_id' => ['nullable', 'integer', 'exists:provinces,id'],
            'district_id' => ['nullable', 'integer', 'exists:districts,id'],
            'media' => ['sometimes', 'array', 'max:5'],
            'media.*' => ['file', 'mimes:jpg,jpeg,png,heic,mp4,mov,webm', 'max:51200'],
        ];
    }
}
