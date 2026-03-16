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
        Schema::table('notifications', function (Blueprint $table) {
            $table->string('title_en')->nullable()->after('title');
            $table->string('title_fr')->nullable()->after('title_en');
            $table->string('title_nl')->nullable()->after('title_fr');
            $table->text('body_en')->nullable()->after('body');
            $table->text('body_fr')->nullable()->after('body_en');
            $table->text('body_nl')->nullable()->after('body_fr');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('notifications', function (Blueprint $table) {
            $table->dropColumn(['title_en', 'title_fr', 'title_nl', 'body_en', 'body_fr', 'body_nl']);
        });
    }
};
