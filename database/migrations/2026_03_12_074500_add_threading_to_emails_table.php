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
            $table->string('thread_id')->nullable()->index()->after('message_id');
            $table->string('in_reply_to')->nullable()->after('thread_id');
            $table->text('references')->nullable()->after('in_reply_to');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('emails', function (Blueprint $table) {
            $table->dropColumn(['thread_id', 'in_reply_to', 'references']);
        });
    }
};
