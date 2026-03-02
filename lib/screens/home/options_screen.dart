import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/settings_service.dart';
import 'package:sixin_front/core/theme/theme_controller.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Opciones')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: SettingsService.instance.watchUi(),
        builder: (context, snap) {
          final data = snap.data ?? {};
          final positionsLang = (data['positionsLang'] ?? 'es').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Idioma de posiciones',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'es', label: Text('Español')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {positionsLang},
                onSelectionChanged: (s) async {
                  await SettingsService.instance.setPositionsLang(s.first);
                },
              ),

              const SizedBox(height: 24),

              Text('Tema', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),

              ValueListenableBuilder<ThemeData>(
                valueListenable: ThemeController.instance.themeNotifier,
                builder: (context, _, __) {
                  final isDark = ThemeController.instance.isDark;
                  return SwitchListTile(
                    title: const Text('Modo oscuro'),
                    subtitle: Text(isDark ? 'Oscuro' : 'Claro'),
                    value: isDark,
                    onChanged: (v) => ThemeController.instance.toggleTheme(v),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
