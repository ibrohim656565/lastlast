<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\EmergencyContactResource;
use App\Models\EmergencyContact;
use Illuminate\Http\Request;

class EmergencyContactController extends Controller
{
    public function index(Request $request)
    {
        $request->validate([
            'category' => ['sometimes', 'in:police,ambulance,fire,gas,rescue_service,other'],
        ]);

        $contacts = EmergencyContact::query()
            ->ofCategory($request->get('category'))
            ->orderBy('category')
            ->get();

        return EmergencyContactResource::collection($contacts);
    }
}
