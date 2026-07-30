<?php

namespace Database\Seeders;

use App\Models\District;
use App\Models\Province;
use Illuminate\Database\Seeder;

class DistrictSeeder extends Seeder
{
    /**
     * A representative handful of real districts per province, not an
     * exhaustive administrative-division list.
     */
    public function run(): void
    {
        $byProvince = [
            'Dushanbe' => [
                ['name_tg' => 'Исмоили Сомонӣ', 'name_ru' => 'Исмоили Сомони', 'name_en' => 'Ismoili Somoni'],
                ['name_tg' => 'Фирдавсӣ', 'name_ru' => 'Фирдавси', 'name_en' => 'Firdavsi'],
                ['name_tg' => 'Шоҳмансур', 'name_ru' => 'Шохмансур', 'name_en' => 'Shohmansur'],
                ['name_tg' => 'Сино', 'name_ru' => 'Сино', 'name_en' => 'Sino'],
            ],
            'Sughd' => [
                ['name_tg' => 'Хуҷанд', 'name_ru' => 'Худжанд', 'name_en' => 'Khujand'],
                ['name_tg' => 'Исфара', 'name_ru' => 'Исфара', 'name_en' => 'Isfara'],
                ['name_tg' => 'Конибодом', 'name_ru' => 'Канибадам', 'name_en' => 'Konibodom'],
            ],
            'Khatlon' => [
                ['name_tg' => 'Кӯлоб', 'name_ru' => 'Куляб', 'name_en' => 'Kulob'],
                ['name_tg' => 'Бохтар', 'name_ru' => 'Бохтар', 'name_en' => 'Bokhtar'],
                ['name_tg' => 'Восеъ', 'name_ru' => 'Восе', 'name_en' => 'Vose'],
            ],
            'Districts of Republican Subordination (DRS)' => [
                ['name_tg' => 'Ваҳдат', 'name_ru' => 'Вахдат', 'name_en' => 'Vahdat'],
                ['name_tg' => 'Ҳисор', 'name_ru' => 'Гиссар', 'name_en' => 'Hisor'],
                ['name_tg' => 'Турсунзода', 'name_ru' => 'Турсунзаде', 'name_en' => 'Tursunzoda'],
            ],
            'Gorno-Badakhshan Autonomous Province (GBAO)' => [
                ['name_tg' => 'Хоруғ', 'name_ru' => 'Хорог', 'name_en' => 'Khorog'],
                ['name_tg' => 'Ишкошим', 'name_ru' => 'Ишкашим', 'name_en' => 'Ishkashim'],
            ],
        ];

        foreach ($byProvince as $provinceNameEn => $districts) {
            $province = Province::query()->where('name_en', $provinceNameEn)->firstOrFail();

            foreach ($districts as $district) {
                District::query()->updateOrCreate(
                    ['province_id' => $province->id, 'name_en' => $district['name_en']],
                    [...$district, 'province_id' => $province->id],
                );
            }
        }
    }
}
