<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Province extends Model
{
    use HasFactory;

    protected $fillable = ['name_tg', 'name_ru', 'name_en'];

    public function districts()
    {
        return $this->hasMany(District::class);
    }

    public function incidents()
    {
        return $this->hasMany(Incident::class);
    }

    public function safePoints()
    {
        return $this->hasMany(SafePoint::class);
    }
}
