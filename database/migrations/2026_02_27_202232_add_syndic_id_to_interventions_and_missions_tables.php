<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('interventions', function (Blueprint $table) {
            $table->foreignId('syndic_id')->nullable()->after('building_id')->constrained('syndics')->onDelete('set null');
        });

        Schema::table('missions', function (Blueprint $table) {
            $table->foreignId('syndic_id')->nullable()->after('building_id')->constrained('syndics')->onDelete('set null');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('interventions', function (Blueprint $table) {
            $table->dropForeign(['syndic_id']);
            $table->dropColumn('syndic_id');
        });

        Schema::table('missions', function (Blueprint $table) {
            $table->dropForeign(['syndic_id']);
            $table->dropColumn('syndic_id');
        });
    }
};
