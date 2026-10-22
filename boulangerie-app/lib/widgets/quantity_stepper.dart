import 'package:flutter/material.dart';

import '../core/format.dart';
import 'dialogs.dart';

/// [−] 12 [+] avec de gros boutons ; toucher le nombre ouvre le clavier.
/// `value == null` affiche « ? » (pas encore compté) : « − » donne 0, « + » donne 1.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.dialogTitle,
    this.max,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final String dialogTitle;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = value ?? 0;
    final canAdd = max == null || current < max!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(
          icon: Icons.remove_rounded,
          onPressed: value == null || current > 0 ? () => onChanged(value == null ? 0 : current - 1) : null,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final typed = await askNumber(context, title: dialogTitle, initial: value, max: max);
            if (typed != null) onChanged(typed);
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 72),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value == null ? '?' : formatInt(current),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: value == null ? scheme.outline : null,
                  ),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.add_rounded,
          onPressed: canAdd ? () => onChanged(value == null ? 1 : current + 1) : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: IconButton.filledTonal(
        iconSize: 30,
        constraints: const BoxConstraints.tightFor(width: 56, height: 56),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
