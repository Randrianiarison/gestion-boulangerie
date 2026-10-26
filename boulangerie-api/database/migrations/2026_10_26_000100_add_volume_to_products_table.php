<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Jus vendus à la bouteille : chaque bouteille a sa contenance (orange 1 L, coco 50 cl).
        Schema::table('products', function (Blueprint $table) {
            $table->unsignedInteger('volume_ml')->nullable()->after('size');
            $table->dropUnique(['name_fr', 'format', 'size']);
            $table->unique(['name_fr', 'format', 'size', 'volume_ml']);
        });

        // Plus de vente au verre : les anciens produits restent pour l'historique, mais ne se vendent plus.
        DB::table('products')->where('format', 'glass')->update(['active' => false]);
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropUnique(['name_fr', 'format', 'size', 'volume_ml']);
            $table->dropColumn('volume_ml');
            $table->unique(['name_fr', 'format', 'size']);
        });
    }
};
