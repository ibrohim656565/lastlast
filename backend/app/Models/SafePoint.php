<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class SafePoint extends Model
{
    use HasFactory;

    protected $fillable = [
        'type', 'name', 'phone', 'province_id', 'district_id', 'address',
    ];

    protected static function booted(): void
    {
        static::addGlobalScope('withLatLng', function (Builder $builder) {
            $builder->addSelect([
                'safe_points.*',
                DB::raw('ST_Y(safe_points.location::geometry) as lat'),
                DB::raw('ST_X(safe_points.location::geometry) as lng'),
            ]);
        });
    }

    public function setPoint(float $lat, float $lng): void
    {
        DB::statement(
            'UPDATE safe_points SET location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography WHERE id = ?',
            [$lng, $lat, $this->id]
        );

        $this->setAttribute('lat', $lat);
        $this->setAttribute('lng', $lng);
    }

    public function province()
    {
        return $this->belongsTo(Province::class);
    }

    public function district()
    {
        return $this->belongsTo(District::class);
    }

    public function scopeOfType(Builder $query, ?string $type): Builder
    {
        return $type ? $query->where('type', $type) : $query;
    }

    public function scopeNearby(Builder $query, ?float $lat, ?float $lng, ?float $radiusKm = null): Builder
    {
        if ($lat === null || $lng === null) {
            return $query;
        }

        $query->selectRaw(
            'ST_Distance(safe_points.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography) as distance_meters',
            [$lng, $lat]
        );

        if ($radiusKm) {
            $query->whereRaw(
                'ST_DWithin(safe_points.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)',
                [$lng, $lat, $radiusKm * 1000]
            );
        }

        return $query->orderBy('distance_meters', 'asc');
    }
}
