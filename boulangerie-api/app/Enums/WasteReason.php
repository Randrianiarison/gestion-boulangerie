<?php

namespace App\Enums;

enum WasteReason: string
{
    case Expired = 'expired';
    case Damaged = 'damaged';
    case Other = 'other';
}
