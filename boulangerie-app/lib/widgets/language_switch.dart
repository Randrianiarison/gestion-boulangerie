import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/labels.dart';
import '../core/settings.dart';

/// Malagasy / Français, mémorisé sur le téléphone.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(localeProvider).languageCode;

    return SegmentedButton<String>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(0, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      segments: [
        ButtonSegment(value: 'mg', label: Text(l10n.languageMalagasy), icon: const Icon(Icons.translate_rounded)),
        ButtonSegment(value: 'fr', label: Text(l10n.languageFrench), icon: const Icon(Icons.translate_rounded)),
      ],
      selected: {current},
      onSelectionChanged: (selection) => ref.read(localeProvider.notifier).change(Locale(selection.first)),
    );
  }
}
