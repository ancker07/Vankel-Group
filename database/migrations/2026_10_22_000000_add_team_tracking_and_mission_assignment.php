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
        // Last known position of each user (sent by the mobile app)
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('latitude', 10, 7)->nullable()->after('fcm_token');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->timestamp('location_updated_at')->nullable()->after('longitude');
        });

        // User a mission is linked to when it is approved
        Schema::table('missions', function (Blueprint $table) {
            $table->foreignId('assigned_user_id')->nullable()->after('syndic_id')->constrained('users')->nullOnDelete();
        });

        // History of who was assigned to which mission / intervention, and when
        Schema::create('assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->nullable()->constrained('missions')->nullOnDelete();
            $table->foreignId('intervention_id')->nullable()->constrained('interventions')->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('assigned_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('assigned_at');
            $table->timestamp('unassigned_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('assignments');

        Schema::table('missions', function (Blueprint $table) {
            $table->dropForeign(['assigned_user_id']);
            $table->dropColumn('assigned_user_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['latitude', 'longitude', 'location_updated_at']);
        });
    }
};
