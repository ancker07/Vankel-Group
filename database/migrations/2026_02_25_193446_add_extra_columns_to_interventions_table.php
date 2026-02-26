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
            $table->text('admin_feedback')->nullable();
            $table->string('delay_reason')->nullable();
            $table->text('delay_details')->nullable();
            $table->dateTime('delayed_reschedule_date')->nullable();
            $table->dateTime('completed_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('interventions', function (Blueprint $table) {
            $table->dropColumn(['admin_feedback', 'delay_reason', 'delay_details', 'delayed_reschedule_date', 'completed_at']);
        });
    }
};
