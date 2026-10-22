<?php

namespace App\Console\Commands;

use App\Exceptions\BusinessRuleException;
use App\Services\DayClosingService;
use App\Services\DayLock;
use App\Support\Dates;
use Carbon\CarbonImmutable;
use Illuminate\Console\Command;

/**
 * Clôture de rattrapage sans comptage : les lots expirés passent en invendus,
 * aucune vente n'est déduite. Idempotente : relancer la commande ne change rien.
 */
class CloseDayCommand extends Command
{
    protected $signature = 'stock:close-day {date? : Journée à clôturer (AAAA-MM-JJ), hier par défaut}';

    protected $description = 'Clôture une journée oubliée : les lots expirés passent en invendus (sans comptage)';

    public function handle(DayClosingService $closings, DayLock $lock): int
    {
        $input = $this->argument('date');
        $date = $input === null ? CarbonImmutable::yesterday() : Dates::parseIso($input);

        if ($date === null) {
            $this->error("Date invalide : {$input} (format attendu AAAA-MM-JJ).");

            return self::FAILURE;
        }

        $label = $date->format('d/m/Y');
        $reason = $lock->blockedReason($date);

        if (in_array($reason, ['day_closed', 'period_closed'], true)) {
            $this->info("Journée du {$label} déjà clôturée : rien à faire.");

            return self::SUCCESS;
        }

        try {
            $closing = $closings->closeAutomatically($date);
        } catch (BusinessRuleException $e) {
            $this->error($e->getMessage());

            return self::FAILURE;
        }

        if ($closing === null) {
            $this->info("Journée du {$label} déjà clôturée : rien à faire.");

            return self::SUCCESS;
        }

        $quantity = (int) $closing->wasteRecords()->sum('quantity');
        $this->info("Journée du {$label} clôturée : {$quantity} invendu(s) enregistré(s).");

        return self::SUCCESS;
    }
}
