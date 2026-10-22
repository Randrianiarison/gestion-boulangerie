<?php

namespace App\Enums;

enum EmployeeRole: string
{
    case Preparation = 'preparation';
    case Sales = 'sales';
    case Delivery = 'delivery';
    case Other = 'other';
}
