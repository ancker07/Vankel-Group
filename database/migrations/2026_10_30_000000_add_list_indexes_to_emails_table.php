<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('emails', function (Blueprint $table) {
            $table->index('received_at');
            $table->index('ingestion_status');
            $table->index('in_reply_to');
        });
    }

    public function down(): void
    {
        Schema::table('emails', function (Blueprint $table) {
            $table->dropIndex(['received_at']);
            $table->dropIndex(['ingestion_status']);
            $table->dropIndex(['in_reply_to']);
        });
    }
};
