<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\CloseDayRequest;
use App\Http\Resources\DayClosingResource;
use App\Http\Resources\StockRowResource;
use App\Models\DayClosing;
use App\Models\User;
use App\Services\DayClosingService;
use App\Services\DayLock;
use App\Services\StockService;
use App\Support\Dates;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class DayClosingController extends Controller
{
    public function __construct(
        private readonly DayClosingService $closings,
        private readonly StockService $stock,
        private readonly DayLock $lock,
    ) {}

    /** Écran de clôture : disponible par produit à compter, ou résumé si la journée est déjà clôturée. */
    public function show(Request $request, string $date): JsonResponse
    {
        return response()->json(['data' => $this->state($this->parseDate($date), $request->user())]);
    }

    public function store(CloseDayRequest $request, string $date): JsonResponse
    {
        $day = $this->parseDate($date);
        $this->closings->close($day, $request->validated('items'), $request->user());

        return response()->json(['data' => $this->state($day, $request->user())], 201);
    }

    /** Annule la dernière clôture (owner) pour pouvoir recompter. */
    public function destroy(Request $request, string $date): JsonResponse
    {
        Gate::authorize('delete', DayClosing::class);

        $day = $this->parseDate($date);
        $this->closings->cancel($day);

        return response()->json(['data' => $this->state($day, $request->user())]);
    }

    private function state(CarbonImmutable $day, User $user): array
    {
        $closing = DayClosing::with(['sales.product', 'wasteRecords.product', 'user'])
            ->where('date', $day->toDateString())
            ->first();
        $blockedReason = $closing ? null : $this->lock->blockedReason($day);

        return [
            'date' => $day->toDateString(),
            'closed' => $closing !== null,
            'can_close' => $closing === null && $blockedReason === null,
            'blocked_reason' => $blockedReason,
            'last_closed_on' => $this->lock->lastClosedDate()?->toDateString(),
            'items' => $closing ? [] : StockRowResource::collection($this->stock->availabilityOn($day))->resolve(),
            'closing' => $closing ? (new DayClosingResource($closing))->resolve() : null,
            'can_cancel' => $closing !== null
                && $user->can('delete', DayClosing::class)
                && $this->closings->cancelBlockedReason($closing) === null,
        ];
    }

    private function parseDate(string $date): CarbonImmutable
    {
        return Dates::parseIso($date) ?? abort(404);
    }
}
