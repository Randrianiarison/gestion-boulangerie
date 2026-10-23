<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Même produit en plusieurs tailles, chacune avec son prix (pain au chocolat petit / grand).
        Schema::table('products', function (Blueprint $table) {
            $table->string('size', 10)->nullable()->after('format'); // small | medium | large
            $table->dropUnique(['name_fr', 'format']);
            $table->unique(['name_fr', 'format', 'size']);
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropUnique(['name_fr', 'format', 'size']);
            $table->dropColumn('size');
            $table->unique(['name_fr', 'format']);
        });
    }
};
