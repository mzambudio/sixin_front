import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

class ThemeEditor {
  static Future<void> show(BuildContext context) async {
    final controller = ThemeController.instance;

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Tema'),
          content: ValueListenableBuilder<ThemeData>(
            valueListenable: controller.themeNotifier,
            builder: (_, __, ___) {
              return SwitchListTile(
                title: const Text('Modo oscuro'),
                value: controller.isDark,
                onChanged: (v) => controller.toggleTheme(v),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}
