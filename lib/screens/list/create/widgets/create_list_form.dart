import 'package:flutter/material.dart';
import 'package:sixin_front/core/constants/list_form_constants.dart';

class CreateListForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool submitted;

  // Lugar
  final String? selectedPlace;
  final ValueChanged<String?> onPlaceChanged;
  final TextEditingController customPlaceCtrl;

  // Fecha/hora
  final DateTime? date;
  final TimeOfDay? time;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  // Precio
  final TextEditingController totalPriceCtrl;

  // Nivel
  final Set<String> levelsSelected;
  final void Function(String level, bool selected) onToggleLevel;

  // Sistema
  final Set<String> systemsSelected;
  final void Function(String system, bool selected) onToggleSystem;

  // Descripción
  final TextEditingController descCtrl;

  const CreateListForm({
    super.key,
    required this.formKey,
    required this.submitted,
    required this.selectedPlace,
    required this.onPlaceChanged,
    required this.customPlaceCtrl,
    required this.date,
    required this.time,
    required this.onPickDate,
    required this.onPickTime,
    required this.totalPriceCtrl,
    required this.levelsSelected,
    required this.onToggleLevel,
    required this.systemsSelected,
    required this.onToggleSystem,
    required this.descCtrl,
  });

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Lugar
          DropdownButtonFormField<String>(
            initialValue: selectedPlace,
            decoration: const InputDecoration(
              labelText: 'Lugar',
              border: OutlineInputBorder(),
            ),
            items: [
              ...kPlaces.map(
                (place) => DropdownMenuItem(value: place, child: Text(place)),
              ),
              const DropdownMenuItem(
                value: kCustomPlaceValue,
                child: Text('Otro (personalizado)'),
              ),
            ],
            onChanged: onPlaceChanged,
            validator: (value) {
              if (value == null) return 'Selecciona un lugar';
              if (value == kCustomPlaceValue &&
                  customPlaceCtrl.text.trim().isEmpty) {
                return 'Escribe el lugar personalizado';
              }
              return null;
            },
          ),

          // Lugar personalizado
          if (selectedPlace == kCustomPlaceValue) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: customPlaceCtrl,
              decoration: const InputDecoration(
                labelText: 'Lugar personalizado',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (selectedPlace == kCustomPlaceValue &&
                    (v == null || v.trim().isEmpty)) {
                  return 'Escribe el lugar';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 12),

          // Fecha y hora
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    date == null ? 'Seleccionar día' : _formatDate(date!),
                  ),
                  onPressed: onPickDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    time == null ? 'Seleccionar hora' : _formatTime(time!),
                  ),
                  onPressed: onPickTime,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Precio total
          TextFormField(
            controller: totalPriceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Precio total (€) (opcional)',
              border: OutlineInputBorder(),
              hintText: 'Ej: 24.50',
            ),
          ),

          const SizedBox(height: 12),

          // Nivel
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nivel de juego',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '(puedes seleccionar uno o más)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in kLevelsEs)
                FilterChip(
                  showCheckmark: false,
                  label: Text(l),
                  selected: levelsSelected.contains(l),
                  onSelected: (selected) => onToggleLevel(l, selected),
                ),
            ],
          ),
          if (submitted && levelsSelected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona al menos un nivel',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Sistema de juego
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sistema de juego',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '(puedes seleccionar uno o más)',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in kSystems)
                FilterChip(
                  showCheckmark: false,
                  label: Text(s),
                  selected: systemsSelected.contains(s),
                  onSelected: (selected) => onToggleSystem(s, selected),
                ),
            ],
          ),
          if (submitted && systemsSelected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona al menos un sistema',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Descripción
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
