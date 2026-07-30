<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateIncidentStatusRequest;
use App\Models\District;
use App\Models\Incident;
use App\Models\Province;
use App\Services\NotificationService;
use Illuminate\Http\Request;

class IncidentController extends Controller
{
    /**
     * Forward-only status machine: new -> verified -> dispatched -> resolved.
     * Regular admins/dispatchers may also jump ahead (e.g. new -> dispatched)
     * but never move backward.
     */
    private const STATUS_ORDER = ['new', 'verified', 'dispatched', 'resolved'];

    public function index(Request $request)
    {
        $filters = $request->only(['type', 'district_id', 'province_id', 'status', 'from', 'to']);

        $incidents = Incident::query()
            ->with(['province', 'district', 'reporter'])
            ->ofType($filters['type'] ?? null)
            ->ofStatus($filters['status'] ?? null)
            ->inProvince($filters['province_id'] ?? null)
            ->inDistrict($filters['district_id'] ?? null)
            ->reportedBetween($filters['from'] ?? null, $filters['to'] ?? null)
            ->latest()
            ->paginate(25)
            ->withQueryString();

        $provinces = Province::orderBy('name_en')->get();
        $districts = District::orderBy('name_en')->get();

        return view('admin.incidents.index', compact('incidents', 'provinces', 'districts', 'filters'));
    }

    public function show(Incident $incident)
    {
        $incident->load(['province', 'district', 'media', 'reporter']);

        $nextStatuses = $this->allowedNextStatuses($incident->status, $this->isSuperAdmin());

        return view('admin.incidents.show', compact('incident', 'nextStatuses'));
    }

    public function updateStatus(
        UpdateIncidentStatusRequest $request,
        Incident $incident,
        NotificationService $notifications
    ) {
        $newStatus = $request->validated()['status'];
        $currentIndex = array_search($incident->status, self::STATUS_ORDER, true);
        $newIndex = array_search($newStatus, self::STATUS_ORDER, true);

        if ($newIndex < $currentIndex && ! $this->isSuperAdmin()) {
            return back()->withErrors(['status' => 'Status cannot move backward.']);
        }

        $incident->status = $newStatus;

        match ($newStatus) {
            'verified' => $incident->verified_at ??= now(),
            'dispatched' => $incident->dispatched_at ??= now(),
            'resolved' => $incident->resolved_at ??= now(),
            default => null,
        };

        $incident->save();

        if ($newStatus === 'verified') {
            $notifications->notifyIncidentVerified($incident);
        }

        return back()->with('status', "Incident #{$incident->id} marked as {$newStatus}.");
    }

    private function allowedNextStatuses(string $current, bool $isSuperAdmin): array
    {
        $currentIndex = array_search($current, self::STATUS_ORDER, true);

        if ($isSuperAdmin) {
            return self::STATUS_ORDER;
        }

        return array_slice(self::STATUS_ORDER, $currentIndex);
    }

    private function isSuperAdmin(): bool
    {
        // No separate super-admin role exists yet; every `admin` is treated
        // as a super-admin for the backward-transition exception described
        // in API_CONTRACT.md, while `dispatcher` stays forward-only.
        return optional(auth('web')->user())->role === 'admin';
    }
}
