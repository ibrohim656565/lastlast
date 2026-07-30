<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Requires the connecting DB user to have CREATE privilege (or the
     * extension to be pre-installed by a superuser). See README.md.
     */
    public function up(): void
    {
        DB::statement('CREATE EXTENSION IF NOT EXISTS postgis');
    }

    public function down(): void
    {
        // Intentionally not dropped — other tables/data may depend on it.
    }
};
