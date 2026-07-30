<?php

namespace Database\Seeders;

use App\Models\Province;
use Illuminate\Database\Seeder;

class ProvinceSeeder extends Seeder
{
    /**
     * The 5 top-level regions of Tajikistan: the capital Dushanbe (a
     * city-region in its own right), Sughd, Khatlon, DRS/RRP (districts of
     * republican subordination), and GBAO (Gorno-Badakhshan).
     */
    public function run(): void
    {
        $provinces = [
            ['name_tg' => 'Душанбе', 'name_ru' => 'Душанбе', 'name_en' => 'Dushanbe'],
            ['name_tg' => 'Суғд', 'name_ru' => 'Согд', 'name_en' => 'Sughd'],
            ['name_tg' => 'Хатлон', 'name_ru' => 'Хатлон', 'name_en' => 'Khatlon'],
            ['name_tg' => 'Ноҳияҳои тобеи ҷумҳурӣ', 'name_ru' => 'Районы республиканского подчинения', 'name_en' => 'Districts of Republican Subordination (DRS)'],
            ['name_tg' => 'Вилояти Мухтори Кӯҳистони Бадахшон', 'name_ru' => 'Горно-Бадахшанская автономная область', 'name_en' => 'Gorno-Badakhshan Autonomous Province (GBAO)'],
        ];

        foreach ($provinces as $province) {
            Province::query()->updateOrCreate(['name_en' => $province['name_en']], $province);
        }
    }
}
