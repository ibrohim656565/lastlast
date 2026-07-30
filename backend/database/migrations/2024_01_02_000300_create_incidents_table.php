<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('incidents', function (Blueprint $table) {
            $table->id();
            $table->uuid('client_uuid');
            $table->enum('type', ['flood', 'landslide', 'earthquake', 'fire', 'avalanche', 'other']);
            $table->enum('status', ['new', 'verified', 'dispatched', 'resolved'])->default('new');
            $table->text('description')->nullable();
            $table->unsignedInteger('injured_count')->default(0);
            $table->boolean('road_blocked')->default(false);
            $table->foreignId('province_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('district_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('reporter_id')->constrained('users')->cascadeOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('dispatched_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();

            // Idempotent offline sync: the same device can only create one
            // incident per client-generated UUID per reporter.
            $table->unique(['reporter_id', 'client_uuid']);
            $table->index(['type']);
            $table->index(['status']);
        });

        // Eloquent migrations don't support PostGIS geography columns, so
        // the point column and its spatial index are added with raw SQL.
        DB::statement('ALTER TABLE incidents ADD COLUMN location geography(Point, 4326) NULL');
        DB::statement('CREATE INDEX incidents_location_gist ON incidents USING GIST (location)');
    }

    public function down(): void
    {
        Schema::dropIfExists('incidents');
    }
};
