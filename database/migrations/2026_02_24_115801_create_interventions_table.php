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
        Schema::create('interventions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('building_id')->constrained('buildings')->onDelete('cascade');
            $table->string('title');
            $table->text('description');
            $table->string('status')->default('PENDING');
            $table->string('sector')->nullable();
            $table->string('category')->nullable();
            $table->dateTime('scheduled_date')->nullable();
            $table->string('urgency')->default('MEDIUM');
            $table->string('on_site_contact_name')->nullable();
            $table->string('on_site_contact_phone')->nullable();
            $table->string('on_site_contact_email')->nullable();
            $table->timestamps();
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('interventions');
    }
};
