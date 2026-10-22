<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\ReportRequest;
use App\Services\ProfitCalculator;
use Illuminate\Http\JsonResponse;

class ReportController extends Controller
{
    /** GET /reports/summary?period=week|month&date=AAAA-MM-JJ (owner). */
    public function summary(ReportRequest $request, ProfitCalculator $calculator): JsonResponse
    {
        return response()->json([
            'data' => $calculator->summary($request->validated('period'), $request->dateOrToday('date')),
        ]);
    }
}
