<?php

return [
    'errors' => [
        'insufficient_stock' => "Stock insuffisant pour :product : :available disponible(s), :requested demandé(s). Enregistrez d'abord la production.",
        'remaining_exceeds_available' => 'Pour :product, le restant compté (:remaining) dépasse le disponible (:available).',
        'closing_missing_products' => 'Comptez aussi le restant de : :products.',
        'recovered_without_waste' => "Aucun invendu pour :product : impossible d'indiquer un montant récupéré.",
        'future_date' => "Impossible d'enregistrer une opération à une date future (:date).",
        'day_closed' => 'La journée du :date est déjà clôturée.',
        'period_closed' => 'La journée du :last est déjà clôturée : le :date ne peut plus être modifié.',
        'closing_not_found' => "La journée du :date n'est pas clôturée.",
        'closing_not_latest' => 'Seule la dernière clôture peut être annulée.',
        'closing_has_later_operations' => "Impossible d'annuler : des ventes ou invendus ont déjà été saisis après le :date.",
        'lot_already_used' => 'Cette production a déjà été vendue en partie : elle ne peut plus être supprimée.',
        'insufficient_ingredient' => 'Stock insuffisant de :ingredient : il reste :available :unit.',
        'invalid_credentials' => 'Numéro de téléphone ou code PIN incorrect.',
        'account_disabled' => 'Ce compte est désactivé. Adressez-vous au propriétaire.',
        'product_has_history' => 'Ce produit a déjà été produit ou vendu : désactivez-le au lieu de le supprimer.',
        'ingredient_has_history' => 'Cet ingrédient a des achats ou des utilisations : désactivez-le au lieu de le supprimer.',
        'employee_has_payments' => 'Cet employé a déjà reçu des paiements : indiquez plutôt sa date de départ.',
        'last_salary_rate' => 'Impossible de supprimer le seul salaire de cet employé.',
        'cannot_modify_self' => 'Vous ne pouvez pas désactiver votre propre compte ni retirer votre rôle de propriétaire.',
        'forbidden' => 'Accès réservé au propriétaire.',
        'unauthenticated' => 'Session expirée : reconnectez-vous.',
        'not_found' => 'Élément introuvable.',
        'too_many_attempts' => 'Trop de tentatives. Réessayez dans une minute.',
        'validation' => 'Certaines informations sont incorrectes.',
        'server_error' => 'Erreur du serveur. Réessayez plus tard.',
    ],

    'formats' => [
        'piece' => 'pièce',
        'glass' => 'verre',
        'bottle' => 'bouteille',
    ],

    'units' => [
        'kg' => 'kg',
        'g' => 'g',
        'l' => 'litre(s)',
        'piece' => 'pièce(s)',
        'sachet' => 'sachet(s)',
    ],
];
