<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('employees', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('phone', 20)->nullable();
            $table->string('role', 20); // preparation | sales | delivery | other
            $table->date('hired_on');
            $table->date('left_on')->nullable();
            $table->timestamps();
        });

        // Historique des salaires : le taux en vigueur un jour donné est le dernier effective_from <= ce jour.
        Schema::create('salary_rates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('monthly_amount');
            $table->date('effective_from');
            $table->timestamps();

            $table->unique(['employee_id', 'effective_from']);
        });

        Schema::create('salary_payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('employee_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('amount');
            $table->date('paid_on')->index();
            $table->string('note')->nullable();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('salary_payments');
        Schema::dropIfExists('salary_rates');
        Schema::dropIfExists('employees');
    }
};
