<?php

namespace App\Http\Requests\Api;

use Illuminate\Foundation\Http\FormRequest;

class SyncIncidentsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Only the batch envelope shape is validated here. Each report's own
     * fields are validated individually inside the controller loop so one
     * malformed report can be reported as an "error" item instead of
     * failing the whole batch (per API_CONTRACT.md).
     */
    public function rules(): array
    {
        return [
            'reports' => ['required', 'array', 'min:1'],
            'reports.*.client_uuid' => ['required', 'uuid'],
        ];
    }
}
