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
        if (Schema::hasTable('bug_reports')) {
            return;
        }

        Schema::create('bug_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')
                ->nullable()
                ->constrained('users')
                ->nullOnDelete();
            $table->string('status', 32)->default('open')->index();
            $table->text('description');
            $table->boolean('include_logs')->default(false);
            $table->string('screenshot_path', 512)->nullable();
            $table->string('app_version', 64)->nullable();
            $table->string('platform', 32)->nullable()->index();
            $table->string('locale', 16)->nullable();
            $table->string('route_name', 191)->nullable();
            $table->json('device_meta')->nullable();
            $table->longText('diagnostics_logs')->nullable();
            $table->timestamps();

            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bug_reports');
    }
};
