<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Deleting a mission only hides it (deleted_at); nothing is removed, so it can be restored. */
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->dropSoftDeletes();
        });
    }
};
