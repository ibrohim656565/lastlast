<?php

namespace Database\Seeders;

use App\Models\EmergencyContact;
use Illuminate\Database\Seeder;

class EmergencyContactSeeder extends Seeder
{
    /**
     * Standard, well-known post-Soviet short emergency numbers used in
     * Tajikistan (dialable nationwide, no area code). 112 is the unified
     * rescue-service line. These are public numbers, not invented ones.
     */
    public function run(): void
    {
        $contacts = [
            ['category' => 'fire', 'name' => 'Fire Service', 'phone' => '101'],
            ['category' => 'police', 'name' => 'Police', 'phone' => '102'],
            ['category' => 'ambulance', 'name' => 'Ambulance', 'phone' => '103'],
            ['category' => 'gas', 'name' => 'Gas Emergency Service', 'phone' => '104'],
            ['category' => 'rescue_service', 'name' => 'Unified Rescue Service', 'phone' => '112'],
        ];

        foreach ($contacts as $contact) {
            EmergencyContact::query()->updateOrCreate(
                ['category' => $contact['category'], 'phone' => $contact['phone']],
                $contact,
            );
        }
    }
}
