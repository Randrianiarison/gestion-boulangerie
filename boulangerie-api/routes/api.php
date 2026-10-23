<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DayClosingController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\IngredientController;
use App\Http\Controllers\Api\IngredientPurchaseController;
use App\Http\Controllers\Api\IngredientUsageController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\ProductionController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\SalaryPaymentController;
use App\Http\Controllers\Api\SalaryRateController;
use App\Http\Controllers\Api\SaleController;
use App\Http\Controllers\Api\StockController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\WasteRecordController;
use Illuminate\Support\Facades\Route;

Route::pattern('date', '\d{4}-\d{2}-\d{2}');

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:login');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    Route::get('/dashboard', DashboardController::class);

    // Produits, stock et production (tous ; modification du catalogue réservée à l'owner).
    Route::apiResource('products', ProductController::class);
    Route::get('/stock', [StockController::class, 'index']);
    Route::get('/production', [ProductionController::class, 'index']);
    Route::post('/production', [ProductionController::class, 'store'])->middleware('idempotent');
    Route::delete('/production/{stockLot}', [ProductionController::class, 'destroy']);

    // Ventes, clôture de journée et invendus.
    Route::get('/sales', [SaleController::class, 'index']);
    Route::post('/sales', [SaleController::class, 'store'])->middleware('idempotent');
    Route::get('/day-closing/{date}', [DayClosingController::class, 'show']);
    Route::post('/day-closing/{date}', [DayClosingController::class, 'store']);
    Route::delete('/day-closing/{date}', [DayClosingController::class, 'destroy']);
    Route::get('/waste-records', [WasteRecordController::class, 'index']);
    Route::post('/waste-records', [WasteRecordController::class, 'store']);
    Route::patch('/waste-records/{wasteRecord}', [WasteRecordController::class, 'update']);

    // Ingrédients : achats et utilisations saisis par tous.
    Route::get('/ingredients/stock', [IngredientController::class, 'stock']);
    Route::apiResource('ingredients', IngredientController::class);
    Route::get('/ingredient-purchases', [IngredientPurchaseController::class, 'index']);
    Route::post('/ingredient-purchases', [IngredientPurchaseController::class, 'store']);
    Route::delete('/ingredient-purchases/{ingredientPurchase}', [IngredientPurchaseController::class, 'destroy']);
    Route::get('/ingredient-usages', [IngredientUsageController::class, 'index']);
    Route::post('/ingredient-usages', [IngredientUsageController::class, 'store']);
    Route::delete('/ingredient-usages/{ingredientUsage}', [IngredientUsageController::class, 'destroy']);

    // Owner uniquement (policies) : employés et salaires, dépenses, rapports, comptes.
    Route::apiResource('employees', EmployeeController::class);
    Route::get('/employees/{employee}/balance', [EmployeeController::class, 'balance']);
    Route::get('/employees/{employee}/salary-rates', [SalaryRateController::class, 'index']);
    Route::post('/employees/{employee}/salary-rates', [SalaryRateController::class, 'store']);
    Route::delete('/salary-rates/{salaryRate}', [SalaryRateController::class, 'destroy']);
    Route::get('/employees/{employee}/payments', [SalaryPaymentController::class, 'index']);
    Route::post('/employees/{employee}/payments', [SalaryPaymentController::class, 'store']);
    Route::delete('/salary-payments/{salaryPayment}', [SalaryPaymentController::class, 'destroy']);

    Route::apiResource('expenses', ExpenseController::class);
    Route::post('/expenses/{expense}/pay', [ExpenseController::class, 'pay']);

    Route::get('/reports/summary', [ReportController::class, 'summary']);

    Route::apiResource('users', UserController::class)->only(['index', 'store', 'update']);
});
