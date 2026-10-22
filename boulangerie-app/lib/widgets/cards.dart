import 'package:flutter/material.dart';

import '../core/format.dart';

/// Carte avec un titre, pour regrouper un bloc d'écran.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon, this.trailing});

  final String title;
  final Widget child;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              if (icon != null) ...[Icon(icon, color: theme.colorScheme.primary), const SizedBox(width: 8)],
              Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              ?trailing,
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Ligne « libellé ............ 12 500 Ar ».
class AmountRow extends StatelessWidget {
  const AmountRow({super.key, required this.label, required this.amount, this.bold = false, this.color, this.leading});

  final String label;
  final int amount;
  final bool bold;
  final Color? color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: bold ? FontWeight.bold : null,
          color: color,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(child: Text(label, style: style)),
        Text(formatMoney(amount), style: style),
      ]),
    );
  }
}

/// Pastille colorée : statut d'une facture, alerte de stock…
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 4)],
        // Malgache plus long, gros caractères système : le texte passe à la ligne au lieu de déborder.
        Flexible(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

/// Grosse tuile d'accès rapide (icône + mot) pour l'accueil.
class BigTile extends StatelessWidget {
  const BigTile({super.key, required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ◀ libellé ▶ : jour, semaine ou mois.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.previousTooltip,
    this.nextTooltip,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final String? previousTooltip;
  final String? nextTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton.filledTonal(
        iconSize: 30,
        tooltip: previousTooltip,
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      IconButton.filledTonal(
        iconSize: 30,
        tooltip: nextTooltip,
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ]);
  }
}

/// Le nombre seul, sans « Ar » (quantités).
class CountText extends StatelessWidget {
  const CountText(this.value, {super.key, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(formatInt(value), style: style);
}
