import 'package:flutter/material.dart';
import 'package:sixin_front/core/settings/settings_controller.dart';
import 'position_text.dart';

/// Ajusta estos ids si en tu volley_positions.dart usas otros.
const List<String> kPositionIds = ['OH', 'OPP', 'MB', 'S', 'L', kPosPoly];

Future<String?> showPositionPickerDialog(
  BuildContext context, {
  required String? currentId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Elige tu posición'),
      content: ValueListenableBuilder<String>(
        valueListenable: SettingsController.instance.positionsLang,
        builder: (context, langStr, _) {
          final lang = langFromSetting(langStr);

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final id in kPositionIds) ...[
                    _PositionRow(
                      abbr: positionAbbr(id, lang),
                      name: positionName(id, lang),
                      selected: id == currentId,
                      onTap: () => Navigator.pop(context, id),
                    ),
                    const Divider(height: 1),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _PositionRow extends StatelessWidget {
  final String abbr;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _PositionRow({
    required this.abbr,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _AbbrPill(text: abbr, selected: selected),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
            if (selected) const Icon(Icons.check),
          ],
        ),
      ),
    );
  }
}

class _AbbrPill extends StatelessWidget {
  final String text;
  final bool selected;

  const _AbbrPill({required this.text, required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 56,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.surfaceContainerHighest,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
