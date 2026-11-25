<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'pro_plus_expires_at')) {
                $table->timestamp('pro_plus_expires_at')->nullable()->after('account_type');
            }
            if (!Schema::hasColumn('users', 'vip_boost_credits')) {
                $table->integer('vip_boost_credits')->default(0)->after('pro_plus_expires_at');
            }
            if (!Schema::hasColumn('users', 'quick_replies')) {
                $table->json('quick_replies')->nullable()->after('category_interests');
            }
            if (!Schema::hasColumn('users', 'auto_greeting')) {
                $table->string('auto_greeting', 500)->nullable()->after('quick_replies');
            }
        });

        Schema::table('websites', function (Blueprint $table) {
            if (!Schema::hasColumn('websites', 'is_active')) {
                $table->boolean('is_active')->default(false)->after('users_id');
            }
            if (!Schema::hasColumn('websites', 'business_category')) {
                $table->string('business_category', 100)->nullable()->after('is_active');
            }
            if (!Schema::hasColumn('websites', 'working_hours')) {
                $table->string('working_hours', 100)->nullable()->after('business_category');
            }
            if (!Schema::hasColumn('websites', 'maps_url')) {
                $table->string('maps_url', 500)->nullable()->after('location');
            }
            if (!Schema::hasColumn('websites', 'direct_order_enabled')) {
                $table->boolean('direct_order_enabled')->default(true)->after('maps_url');
            }
        });
    }

    public function down(): void
    {
        Schema::table('websites', function (Blueprint $table) {
            foreach (['direct_order_enabled', 'maps_url', 'working_hours', 'business_category', 'is_active'] as $col) {
                if (Schema::hasColumn('websites', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        Schema::table('users', function (Blueprint $table) {
            foreach (['auto_greeting', 'quick_replies', 'vip_boost_credits', 'pro_plus_expires_at'] as $col) {
                if (Schema::hasColumn('users', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
