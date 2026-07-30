<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class District extends Model
{
    use HasFactory;

    protected $fillable = ['province_id', 'name_tg', 'name_ru', 'name_en'];

    public function province()
    {
        return $this->belongsTo(Province::class);
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
