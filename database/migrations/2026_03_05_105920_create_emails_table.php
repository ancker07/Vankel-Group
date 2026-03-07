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
        Schema::create('emails', function (Blueprint $table) {
            $table->id();
            $table->string('message_id')->unique();
            $table->string('from_address');
            $table->string('from_name')->nullable();
            $table->string('to_address')->nullable();
            $table->string('subject')->nullable();
            $table->text('body_text')->nullable();
            $table->longText('body_html')->nullable();
            $table->timestamp('received_at')->nullable();
            $table->boolean('is_read')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('emails');
    }
};
