<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('safe_points', function (Blueprint $table) {
            $table->id();
            $table->enum('type', ['shelter', 'hospital', 'police', 'emergency_center']);
            $table->string('name');
            $table->string('phone')->nullable();
            $table->foreignId('province_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('district_id')->nullable()->constrained()->nullOnDelete();
            $table->string('address')->nullable();
            $table->timestamps();

            $table->index(['type']);
        });

        DB::statement('ALTER TABLE safe_points ADD COLUMN location geography(Point, 4326) NOT NULL');
        DB::statement('CREATE INDEX safe_points_location_gist ON safe_points USING GIST (location)');
    }

    public function down(): void
    {
        Schema::dropIfExists('safe_points');
    }
};
