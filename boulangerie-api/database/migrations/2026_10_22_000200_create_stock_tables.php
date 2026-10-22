<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('day_closings', function (Blueprint $table) {
            $table->id();
            $table->date('date')->unique();
            $table->string('mode', 10); // counted (écran) | automatic (commande artisan)
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });

        // Un lot par production ; les ventes et invendus le consomment en FIFO.
        Schema::create('stock_lots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->date('produced_on');
            $table->date('expires_on'); // produced_on + shelf_life_days - 1
            $table->unsignedInteger('quantity_produced');
            $table->unsignedInteger('quantity_remaining');
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();

            $table->index(['product_id', 'expires_on']);
            $table->index('produced_on');
        });

        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->date('sold_on')->index();
            $table->unsignedInteger('quantity');
            $table->unsignedInteger('unit_price'); // prix figé au moment de la vente
            $table->unsignedInteger('total');
            $table->string('source', 10); // counter | closing
            $table->foreignId('day_closing_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });

        // Lots consommés par chaque vente, pour pouvoir annuler une clôture.
        Schema::create('sale_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained()->cascadeOnDelete();
            $table->foreignId('stock_lot_id')->constrained()->restrictOnDelete();
            $table->unsignedInteger('quantity');
        });

        Schema::create('waste_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('product_id')->constrained()->restrictOnDelete();
            $table->foreignId('stock_lot_id')->nullable()->constrained()->restrictOnDelete();
            $table->date('date')->index();
            $table->unsignedInteger('quantity');
            $table->string('reason', 10); // expired | damaged | other
            $table->unsignedInteger('unit_price'); // prix de vente du jour, pour la valeur informative
            $table->unsignedInteger('recovered_amount')->default(0); // revendu à prix réduit, compté en recette
            $table->string('note')->nullable();
            $table->foreignId('day_closing_id')->nullable()->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('waste_records');
        Schema::dropIfExists('sale_allocations');
        Schema::dropIfExists('sales');
        Schema::dropIfExists('stock_lots');
        Schema::dropIfExists('day_closings');
    }
};
