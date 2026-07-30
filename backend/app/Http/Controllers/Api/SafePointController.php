<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\SafePointResource;
use App\Models\SafePoint;
use Illuminate\Http\Request;

class SafePointController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'type' => ['sometimes', 'in:shelter,hospital,police,emergency_center'],
            'lat' => ['sometimes', 'numeric', 'between:-90,90'],
            'lng' => ['sometimes', 'numeric', 'between:-180,180'],
            'radius_km' => ['sometimes', 'numeric', 'min:0.1', 'max:1000'],
        ]);

        $lat = $request->has('lat') ? $request->float('lat') : null;
        $lng = $request->has('lng') ? $request->float('lng') : null;

        $safePoints = SafePoint::query()
            ->ofType($request->get('type'))
            ->when($lat !== null && $lng !== null, fn ($q) => $q->nearby($lat, $lng, $request->float('radius_km') ?: null))
            ->when(! ($lat !== null && $lng !== null), fn ($q) => $q->orderBy('name'))
            ->get();

        return SafePointResource::collection($safePoints);
    }
}
