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
        Schema::table('missions', function (Blueprint $table) {
            $table->string('source_type')->nullable()->after('status');
            $table->string('source_message_id')->nullable()->after('source_type');
            $table->string('reference')->nullable()->after('source_message_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropColumn(['source_type', 'source_message_id', 'reference']);
        });
    }
};
