<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('meeting_rooms', function (Blueprint $table): void {
            $table->id();
            $table->string('room_code', 32)->unique(); // e.g. apo-7k2m-9x4p
            $table->string('livekit_room_name', 96)->unique();
            $table->string('title', 160);
            $table->unsignedBigInteger('host_user_id')->index();
            $table->unsignedBigInteger('channel_id')->nullable()->index();
            $table->unsignedBigInteger('ad_id')->nullable()->index();
            $table->unsignedSmallInteger('max_participants')->default(25);
            $table->boolean('e2ee_enabled')->default(false);
            $table->string('e2ee_key_hint', 64)->nullable(); // Public key fingerprint / salt (NEVER raw secret key)
            $table->boolean('is_locked')->default(false);
            $table->boolean('mute_on_entry')->default(false);
            $table->string('region', 32)->default('ma-casablanca');
            $table->string('status', 24)->default('active')->index(); // scheduled | active | ended
            $table->unsignedSmallInteger('active_participants_count')->default(0);
            $table->timestamp('started_at')->nullable();
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();
        });

        Schema::create('meeting_participants', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('meeting_room_id')->index();
            $table->unsignedBigInteger('user_id')->index();
            $table->string('participant_identity', 96);
            $table->string('display_name', 120);
            $table->string('avatar_url', 512)->nullable();
            $table->string('role', 24)->default('participant'); // host | cohost | participant
            $table->string('state', 24)->default('invited'); // invited | joined | left | kicked
            $table->boolean('can_publish')->default(true);
            $table->boolean('can_publish_sources_screen')->default(true);
            $table->timestamp('joined_at')->nullable();
            $table->timestamp('left_at')->nullable();
            $table->timestamps();

            $table->unique(['meeting_room_id', 'user_id']);
            $table->foreign('meeting_room_id')
                ->references('id')
                ->on('meeting_rooms')
                ->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('meeting_participants');
        Schema::dropIfExists('meeting_rooms');
    }
};
