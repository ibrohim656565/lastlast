<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmergencyContact extends Model
{
    use HasFactory;

    protected $fillable = ['category', 'name', 'phone'];

    public function scopeOfCategory($query, ?string $category)
    {
        return $category ? $query->where('category', $category) : $query;
    }
}
