<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Incident;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    public function dashboard()
    {
        return view('admin.dashboard');
    }

    public function stats()
    {
        $total = Incident::query()->count();
        $active = Incident::query()->whereIn('status', ['new', 'verified', 'dispatched'])->count();
        $resolved = Incident::query()->where('status', 'resolved')->count();

        $byRegion = Incident::query()
            ->join('provinces', 'provinces.id', '=', 'incidents.province_id')
            ->select('provinces.id', 'provinces.name_en', DB::raw('count(*) as total'))
            ->groupBy('provinces.id', 'provinces.name_en')
            ->orderByDesc('total')
            ->get();

        $byType = Incident::query()
            ->select('type', DB::raw('count(*) as total'))
            ->groupBy('type')
            ->orderByDesc('total')
            ->get();

        return response()->json([
            'data' => [
                'total' => $total,
                'active' => $active,
                'resolved' => $resolved,
                'by_region' => $byRegion,
                'by_type' => $byType,
            ],
        ]);
    }

    /**
     * Same filters as the incidents table (type, district, province,
     * status, date range), used both here and by
     * Admin\IncidentController@index.
     */
    public function incidentsJson(Request $request)
    {
        $incidents = Incident::query()
            ->ofType($request->get('type'))
            ->ofStatus($request->get('status'))
            ->inProvince($request->integer('province_id') ?: null)
            ->inDistrict($request->integer('district_id') ?: null)
            ->reportedBetween($request->get('from'), $request->get('to'))
            ->latest()
            ->limit(1000)
            ->get();

        return response()->json([
            'data' => $incidents->map(fn (Incident $incident) => [
                'id' => $incident->id,
                'type' => $incident->type,
                'status' => $incident->status,
                'lat' => (float) $incident->lat,
                'lng' => (float) $incident->lng,
                'created_at' => $incident->created_at?->toISOString(),
            ]),
        ]);
    }
}
