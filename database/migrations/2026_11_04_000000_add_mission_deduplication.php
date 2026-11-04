<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Mission de-duplication support:
     *  - missions.thread_id               email thread the mission came from (lookup key)
     *  - missions.possible_duplicate_of_id borderline match an admin should review
     *  - missions.duplicate_score          similarity (0-100) behind that flag
     *  - mission_updates                   follow-up emails attached to an existing mission
     */
    public function up(): void
    {
        Schema::table('missions', function (Blueprint $table) {
            $table->string('thread_id')->nullable()->after('source_message_id')->index();
            $table->unsignedBigInteger('possible_duplicate_of_id')->nullable()->after('reference')->index();
            $table->unsignedTinyInteger('duplicate_score')->nullable()->after('possible_duplicate_of_id');
            $table->index('reference');
        });

        Schema::create('mission_updates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mission_id')->constrained('missions')->cascadeOnDelete();
            $table->foreignId('email_id')->nullable()->constrained('emails')->nullOnDelete();
            $table->string('source_message_id')->nullable();
            $table->string('type')->default('EMAIL_UPDATE'); // EMAIL_UPDATE | MERGED_DUPLICATE (snapshot of a merged mission)
            $table->string('match_reason')->nullable();      // reference | thread | building_title | merge
            $table->unsignedTinyInteger('match_score')->nullable();
            $table->string('subject')->nullable();
            $table->text('summary')->nullable();
            $table->json('data')->nullable();
            $table->timestamps();

            // One email can only ever be attached once (also guards concurrent double processing)
            $table->unique(['mission_id', 'source_message_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mission_updates');

        Schema::table('missions', function (Blueprint $table) {
            $table->dropIndex(['reference']);
            $table->dropColumn(['thread_id', 'possible_duplicate_of_id', 'duplicate_score']);
        });
    }
};
