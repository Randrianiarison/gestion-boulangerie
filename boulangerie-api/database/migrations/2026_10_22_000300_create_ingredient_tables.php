<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ingredients', function (Blueprint $table) {
            $table->id();
            $table->string('name_fr');
            $table->string('name_mg');
            $table->string('unit', 10); // kg | g | l | piece | sachet
            $table->decimal('alert_threshold', 10, 3)->default(0);
            $table->boolean('active')->default(true);
            $table->timestamps();
        });

        Schema::create('ingredient_purchases', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ingredient_id')->constrained()->restrictOnDelete();
            $table->date('purchased_on')->index();
            $table->decimal('quantity', 10, 3);
            $table->unsignedInteger('unit_price');
            $table->unsignedInteger('total'); // montant réellement payé, utilisé pour les charges
            $table->string('supplier')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('ingredient_usages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ingredient_id')->constrained()->restrictOnDelete();
            $table->date('used_on')->index();
            $table->decimal('quantity', 10, 3);
            $table->string('note')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ingredient_usages');
        Schema::dropIfExists('ingredient_purchases');
        Schema::dropIfExists('ingredients');
    }
};
