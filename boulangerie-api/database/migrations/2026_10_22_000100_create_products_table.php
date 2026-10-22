<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Un produit = une saveur + un format (ex. jus de papaye en verre).
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('category', 10); // bread | juice
            $table->string('name_fr');
            $table->string('name_mg');
            $table->string('format', 10)->default('piece'); // piece | glass | bottle
            $table->unsignedInteger('unit_price'); // Ariary
            $table->unsignedSmallInteger('shelf_life_days')->default(1);
            $table->boolean('active')->default(true);
            $table->timestamps();

            $table->unique(['name_fr', 'format']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
