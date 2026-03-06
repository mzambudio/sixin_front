import 'package:flutter/material.dart';

class PositionBadge extends StatelessWidget {
  final String text;
  final bool clickable;

  const PositionBadge({super.key, required this.text, this.clickable = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: clickable ? Border.all(color: scheme.primary) : null,
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
