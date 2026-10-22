<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('expenses', function (Blueprint $table) {
            $table->id();
            $table->string('category', 20); // electricity | rent | transport | packaging | other
            $table->string('label');
            $table->unsignedInteger('amount');
            $table->date('expense_date')->index();
            // Renseigné = charge mensuelle répartie au prorata des jours du mois (électricité, loyer).
            $table->char('period_month', 7)->nullable()->index(); // YYYY-MM
            $table->date('due_date')->nullable();
            $table->date('paid_at')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('expenses');
    }
};
