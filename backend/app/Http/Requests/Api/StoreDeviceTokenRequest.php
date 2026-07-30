<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class StoreDeviceTokenRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'token' => ['required', 'string'],
            'platform' => ['required', 'in:android,ios'],
            'province_id' => ['sometimes', 'nullable', 'integer', 'exists:provinces,id'],
            'district_id' => ['sometimes', 'nullable', 'integer', 'exists:districts,id'],
        ];
    }
}
