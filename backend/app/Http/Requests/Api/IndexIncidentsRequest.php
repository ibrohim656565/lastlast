<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class IndexIncidentsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'type' => ['sometimes', 'in:flood,landslide,earthquake,fire,avalanche,other'],
            'status' => ['sometimes', 'in:new,verified,dispatched,resolved'],
            'province_id' => ['sometimes', 'integer', 'exists:provinces,id'],
            'district_id' => ['sometimes', 'integer', 'exists:districts,id'],
            'lat' => ['sometimes', 'numeric', 'between:-90,90'],
            'lng' => ['sometimes', 'numeric', 'between:-180,180'],
            'radius_km' => ['sometimes', 'numeric', 'min:0.1', 'max:1000'],
            'from' => ['sometimes', 'date'],
            'to' => ['sometimes', 'date'],
            'page' => ['sometimes', 'integer', 'min:1'],
        ];
    }
}
