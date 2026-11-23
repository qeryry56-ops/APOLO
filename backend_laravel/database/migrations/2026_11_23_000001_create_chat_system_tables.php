<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * ByteByteGo "Design a Chat System" storage separation:
 *
 * 1. Relational Database (generic metadata: channels, group membership <= 100,
 *    multi-device sync cursors, push tokens, presence snapshots).
 * 2. Key-Value Message Store mirror (`chat_kv_messages`) partitioned by
 *    `(channel_id, message_id)` with 64-bit monotonic Snowflake `message_id`
 *    and `(channel_id, sender_id, client_message_id)` idempotency constraint.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('chat_channels')) {
            Schema::create('chat_channels', function (Blueprint $table) {
                $table->id();
                $table->string('channel_key', 191)->unique();
                $table->enum('type', ['direct', 'group'])->default('direct')->index();
                $table->string('name', 120)->nullable();
                $table->unsignedSmallInteger('max_members')->default(2);
                $table->unsignedBigInteger('ad_id')->nullable()->index();
                $table->string('ad_title', 255)->nullable();
                $table->string('ad_price', 64)->nullable();
                $table->string('ad_image', 512)->nullable();
                $table->unsignedBigInteger('created_by')->nullable()->index();
                $table->unsignedBigInteger('last_message_id')->default(0)->index();
                $table->string('last_message_preview', 255)->nullable();
                $table->timestamp('last_message_at')->nullable()->index();
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('chat_channel_members')) {
            Schema::create('chat_channel_members', function (Blueprint $table) {
                $table->id();
                $table->foreignId('channel_id')
                    ->constrained('chat_channels')
                    ->cascadeOnDelete();
                $table->unsignedBigInteger('user_id')->index();
                $table->enum('role', ['owner', 'admin', 'member'])->default('member');
                $table->unsignedBigInteger('last_read_message_id')->default(0);
                $table->timestamp('muted_until')->nullable();
                $table->timestamp('joined_at')->useCurrent();
                $table->timestamps();

                $table->unique(['channel_id', 'user_id'], 'chat_channel_member_unique');
                $table->index(['user_id', 'channel_id'], 'chat_member_user_channels_idx');
            });
        }

        if (! Schema::hasTable('chat_device_sync_cursors')) {
            Schema::create('chat_device_sync_cursors', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->string('device_id', 128);
                $table->foreignId('channel_id')
                    ->constrained('chat_channels')
                    ->cascadeOnDelete();
                $table->unsignedBigInteger('cur_max_message_id')->default(0);
                $table->timestamp('last_synced_at')->nullable();
                $table->timestamps();

                $table->unique(
                    ['user_id', 'device_id', 'channel_id'],
                    'chat_device_sync_unique'
                );
                $table->index(['user_id', 'device_id'], 'chat_device_user_idx');
            });
        }

        if (! Schema::hasTable('chat_push_tokens')) {
            Schema::create('chat_push_tokens', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->index();
                $table->string('device_id', 128);
                $table->enum('platform', ['ios', 'android', 'web'])->default('web');
                $table->enum('provider', ['apns', 'fcm', 'webpush'])->default('fcm');
                $table->string('token', 512);
                $table->boolean('is_active')->default(true)->index();
                $table->timestamp('last_seen_at')->nullable();
                $table->timestamps();

                $table->unique(['user_id', 'device_id'], 'chat_push_user_device_unique');
            });
        }

        if (! Schema::hasTable('chat_user_presence')) {
            Schema::create('chat_user_presence', function (Blueprint $table) {
                $table->unsignedBigInteger('user_id')->primary();
                $table->enum('status', ['online', 'offline'])->default('offline')->index();
                $table->timestamp('last_heartbeat_at')->nullable()->index();
                $table->timestamp('last_active_at')->nullable();
                $table->string('presence_server_id', 64)->nullable();
                $table->timestamps();
            });
        }

        // Durable Key-Value store table mirror:
        // Partition key: channel_id, Clustering key: message_id (64-bit Snowflake)
        if (! Schema::hasTable('chat_kv_messages')) {
            Schema::create('chat_kv_messages', function (Blueprint $table) {
                $table->unsignedBigInteger('channel_id');
                $table->unsignedBigInteger('message_id');
                $table->unsignedBigInteger('sender_id')->index();
                $table->string('client_message_id', 128);
                $table->enum('type', ['text', 'audio', 'image'])->default('text');
                $table->text('body')->nullable();
                $table->json('metadata')->nullable();
                $table->timestamp('created_at')->useCurrent();

                $table->primary(['channel_id', 'message_id'], 'chat_kv_pk');
                $table->unique(
                    ['channel_id', 'sender_id', 'client_message_id'],
                    'chat_kv_idempotency_unique'
                );
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('chat_kv_messages');
        Schema::dropIfExists('chat_user_presence');
        Schema::dropIfExists('chat_push_tokens');
        Schema::dropIfExists('chat_device_sync_cursors');
        Schema::dropIfExists('chat_channel_members');
        Schema::dropIfExists('chat_channels');
    }
};
