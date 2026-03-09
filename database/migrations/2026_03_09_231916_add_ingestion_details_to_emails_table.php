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
        Schema::table('emails', function (Blueprint $table) {
            $table->string('ingestion_status')->default('PENDING')->after('ingested_at');
            $table->text('ingestion_reason')->nullable()->after('ingestion_status');
            $table->json('extracted_data')->nullable()->after('ingestion_reason');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('emails', function (Blueprint $table) {
            $table->dropColumn(['ingestion_status', 'ingestion_reason', 'extracted_data']);
        });
    }
};
