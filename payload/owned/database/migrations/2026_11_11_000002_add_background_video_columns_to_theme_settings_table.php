<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class () extends Migration {
    public function up(): void
    {
        Schema::table('theme_settings', function (Blueprint $table) {
            $table->string('background_light_video')->nullable();
            $table->string('background_dark_video')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('theme_settings', function (Blueprint $table) {
            $table->dropColumn([
                'background_light_video',
                'background_dark_video',
            ]);
        });
    }
};
