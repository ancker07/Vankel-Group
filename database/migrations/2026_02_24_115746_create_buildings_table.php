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
        Schema::create('buildings', function (Blueprint $table) {
            $table->id();
            $table->string('address');
            $table->string('city')->nullable();
            $table->foreignId('syndic_id')->nullable()->constrained('syndics')->onDelete('set null');
            $table->string('phone')->nullable();
            $table->text('admin_note')->nullable();
            $table->string('image_url')->nullable();
            $table->dateTime('installation_date')->nullable();
            $table->timestamps();
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('buildings');
    }
};
