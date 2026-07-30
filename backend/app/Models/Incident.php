<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class Incident extends Model
{
    use HasFactory;

    protected $fillable = [
        'client_uuid',
        'type',
        'status',
        'description',
        'injured_count',
        'road_blocked',
        'province_id',
        'district_id',
        'reporter_id',
        'verified_at',
        'dispatched_at',
        'resolved_at',
    ];

    protected function casts(): array
    {
        return [
            'injured_count' => 'integer',
            'road_blocked' => 'boolean',
            'verified_at' => 'datetime',
            'dispatched_at' => 'datetime',
            'resolved_at' => 'datetime',
        ];
    }

    /**
     * The `location` column is a PostGIS geography(Point,4326) that Eloquent
     * cannot read/write natively. Every query pulls it back out as plain
     * lat/lng floats via ST_Y/ST_X so `$incident->lat` / `->lng` just work.
     */
    protected static function booted(): void
    {
        static::addGlobalScope('withLatLng', function (Builder $builder) {
            $builder->addSelect([
                'incidents.*',
                DB::raw('ST_Y(incidents.location::geometry) as lat'),
                DB::raw('ST_X(incidents.location::geometry) as lng'),
            ]);
        });
    }

    /**
     * Writes the geography column directly with a parameterised raw
     * statement (not user-interpolated SQL, so this is injection-safe).
     */
    public function setPoint(float $lat, float $lng): void
    {
        DB::statement(
            'UPDATE incidents SET location = ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography WHERE id = ?',
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

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function media()
    {
        return $this->hasMany(IncidentMedia::class);
    }

    public function scopeOfType(Builder $query, ?string $type): Builder
    {
        return $type ? $query->where('type', $type) : $query;
    }

    public function scopeOfStatus(Builder $query, ?string $status): Builder
    {
        return $status ? $query->where('status', $status) : $query;
    }

    public function scopeInProvince(Builder $query, ?int $provinceId): Builder
    {
        return $provinceId ? $query->where('province_id', $provinceId) : $query;
    }

    public function scopeInDistrict(Builder $query, ?int $districtId): Builder
    {
        return $districtId ? $query->where('district_id', $districtId) : $query;
    }

    public function scopeReportedBetween(Builder $query, ?string $from, ?string $to): Builder
    {
        if ($from) {
            $query->where('created_at', '>=', $from);
        }

        if ($to) {
            $query->where('created_at', '<=', $to);
        }

        return $query;
    }

    /**
     * ST_DWithin on a geography cast operates in metres and is index-backed
     * by the GIST index on `location`, so this stays fast at scale.
     */
    public function scopeNearby(Builder $query, ?float $lat, ?float $lng, ?float $radiusKm = 50): Builder
    {
        if ($lat === null || $lng === null) {
            return $query;
        }

        $radiusMeters = $radiusKm * 1000;

        return $query
            ->whereRaw(
                'ST_DWithin(incidents.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)',
                [$lng, $lat, $radiusMeters]
            )
            ->orderByRaw(
                'ST_Distance(incidents.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography) asc',
                [$lng, $lat]
            );
    }
}
