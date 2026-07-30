<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\DistrictResource;
use App\Http\Resources\ProvinceResource;
use App\Models\District;
use App\Models\Province;
use Illuminate\Http\Request;

class ReferenceDataController extends Controller
{
    public function provinces()
    {
        return ProvinceResource::collection(Province::orderBy('name_en')->get());
    }

    public function districts(Request $request)
    {
        $request->validate([
            'province_id' => ['sometimes', 'integer', 'exists:provinces,id'],
        ]);

        $districts = District::query()
            ->when($request->filled('province_id'), fn ($q) => $q->where('province_id', $request->integer('province_id')))
            ->orderBy('name_en')
            ->get();

        return DistrictResource::collection($districts);
    }
}
