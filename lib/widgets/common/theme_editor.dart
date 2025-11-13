import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

class ThemeEditor {
  static Future<void> show(BuildContext context) async {
    final tc = ThemeController.instance;

    Color tmpPrimary = tc.primary;
    Color tmpBg = tc.background;
    bool tmpDark = tc.isDark;
    String? selectedPreset = tc.currentPreset;

    final presets = tc.presets;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editor de tema'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: const Text('Modo oscuro'),
                      value: tmpDark,
                      onChanged: (v) {
                        setState(() {
                          tmpDark = v;
                          if (!tmpDark && tmpBg.computeLuminance() < 0.5) tmpBg = Colors.white;
                          if (tmpDark && tmpBg.computeLuminance() >= 0.5) tmpBg = const Color(0xFF1B1B1D);
                          selectedPreset = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(alignment: Alignment.centerLeft, child: Text('Presets')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.entries.map((e) {
                        final name = e.key;
                        final p = e.value;
                        final isSel = selectedPreset == name;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              tmpDark = p.isDark;
                              tmpPrimary = p.primary;
                              tmpBg = p.background;
                              selectedPreset = name;
                            });
                          },
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: isSel ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Container(width: 28, height: 28, color: p.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(name, style: TextStyle(fontSize: 12))),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Align(alignment: Alignment.centerLeft, child: Text('Color primario')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _presetColors().map((c) {
                        final selected = c.value == tmpPrimary.value;
                        return GestureDetector(
                          onTap: () => setState(() {
                            tmpPrimary = c;
                            selectedPreset = null;
                          }),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: selected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: '#${tmpBg.value.toRadixString(16).padLeft(8, '0').substring(2)}',
                      decoration: const InputDecoration(
                        labelText: 'Fondo (hex, p.ej. 1B1B1D)',
                      ),
                      onChanged: (v) {
                        final val = v.replaceAll('#', '');
                        if (val.length == 6) {
                          try {
                            final col = Color(int.parse('0xFF$val'));
                            setState(() {
                              tmpBg = col;
                              selectedPreset = null;
                            });
                          } catch (_) {}
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Align(alignment: Alignment.centerLeft, child: Text('Vista previa')),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      color: tmpBg,
                      alignment: Alignment.center,
                      child: Text('Primary', style: TextStyle(color: tmpPrimary)),
                    ),
                    const SizedBox(height: 8),
                    Text('Modo actual: ${tmpDark ? "Oscuro" : "Claro"}'),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                if (selectedPreset != null) {
                  tc.applyPreset(selectedPreset!);
                } else {
                  tc.setPrimaryColor(tmpPrimary);
                  tc.setBackgroundColor(tmpBg);
                  tc.toggleDark(tmpDark);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  static List<Color> _presetColors() {
    return [
      Colors.blueAccent,
      Colors.teal,
      Colors.indigoAccent,
      Colors.orangeAccent,
      Colors.green,
      Colors.pinkAccent,
      Colors.cyan,
    ];
  }
}
