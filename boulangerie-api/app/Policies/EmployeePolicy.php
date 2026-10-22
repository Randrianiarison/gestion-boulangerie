<?php

namespace App\Policies;

/** Employés, historique des salaires et paiements : owner uniquement. */
class EmployeePolicy extends OwnerOnlyPolicy {}
