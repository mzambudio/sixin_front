import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/services/list_service.dart';
import 'package:flutter/services.dart';
import 'package:sixin_front/core/constants/list_form_constants.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  bool _submitted = false;
  final _formKey = GlobalKey<FormState>();
  String? _selectedPlace;
  final _customPlaceCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  final Set<String> _systemsSelected = {};
  final Set<String> _levelsSelected = {};
  final _totalPriceCtrl = TextEditingController();

  final _descCtrl = TextEditingController();

  bool _isPrivate = false;
  bool _needsApproval = false;
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _customPlaceCtrl.dispose();
    _totalPriceCtrl.dispose();
    super.dispose();
  }

  Future<String> _loadMyUsername(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = snap.data();
    final username = (data?['username'] as String?)?.trim();
    return (username == null || username.isEmpty) ? '(sin username)' : username;
  }

  String _normalizePlace(String p) {
    return p.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  DateTime? _combinedDateTime() {
    if (_date == null || _time == null) return null;
    return DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
  }

  double? _parseTotalPriceOrNull() {
    final raw = _totalPriceCtrl.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;

    final v = double.tryParse(raw);
    if (v == null) throw Exception('Precio inválido');
    if (v < 0) throw Exception('El precio no puede ser negativo');
    return v;
  }

  Future<void> _create() async {
    if (_saving) return;

    setState(() => _submitted = true);

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final uid = user.uid;
      final ownerUsername = await _loadMyUsername(uid);

      final sp = _selectedPlace;
      if (sp == null) {
        throw Exception('Selecciona un lugar');
      }
      final place = sp == kCustomPlaceValue
          ? _normalizePlace(_customPlaceCtrl.text)
          : sp;

      final startAt = _combinedDateTime();
      if (startAt == null) {
        throw Exception('Selecciona día y hora');
      }

      if (_levelsSelected.isEmpty) {
        throw Exception('Selecciona al menos un nivel');
      }

      if (_systemsSelected.isEmpty) {
        throw Exception('Selecciona al menos un sistema');
      }

      final visibility = _isPrivate ? 'private' : 'public';
      final joinPolicy = _needsApproval ? 'approval' : 'open';

      final code = await ListService.instance.createList(
        uid: uid,
        ownerUsername: ownerUsername,
        place: place,
        startAt: startAt,
        totalPrice: _parseTotalPriceOrNull(),
        levels: _levelsSelected.toList()..sort(),
        systems: _systemsSelected.toList()..sort(),
        description: _descCtrl.text,
        visibility: visibility,
        joinPolicy: joinPolicy,
      );

      if (!mounted) return;

      if (code != null) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Código de acceso'),
            content: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado ✅')),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lista creada ✅')));

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear lista')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Lugar
                  DropdownButtonFormField<String>(
                    value: _selectedPlace,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...kPlaces.map(
                        (place) =>
                            DropdownMenuItem(value: place, child: Text(place)),
                      ),
                      const DropdownMenuItem(
                        value: kCustomPlaceValue,
                        child: Text('Otro (personalizado)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPlace = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) return 'Selecciona un lugar';
                      if (value == kCustomPlaceValue &&
                          _customPlaceCtrl.text.trim().isEmpty) {
                        return 'Escribe el lugar personalizado';
                      }
                      return null;
                    },
                  ),
                  // Lugar personalizado
                  if (_selectedPlace == kCustomPlaceValue) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _customPlaceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lugar personalizado',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (_selectedPlace == kCustomPlaceValue &&
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
                            _date == null
                                ? 'Seleccionar día'
                                : '${_date!.day}/${_date!.month}/${_date!.year}',
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _time == null
                                ? 'Seleccionar hora'
                                : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                          ),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Precio total
                  TextFormField(
                    controller: _totalPriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio total (€) (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'Ej: 24.50',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nivel
                  Text(
                    'Nivel de juego',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '(puedes seleccionar uno o más)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in kLevelsEs)
                        FilterChip(
                          showCheckmark: false,
                          label: Text(l),
                          selected: _levelsSelected.contains(l),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _levelsSelected.add(l);
                              } else {
                                _levelsSelected.remove(l);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_submitted && _levelsSelected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecciona al menos un nivel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Sistema de juego
                  Text(
                    'Sistema de juego',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '(puedes seleccionar uno o más)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in kSystems)
                        FilterChip(
                          showCheckmark: false,
                          label: Text(s),
                          selected: _systemsSelected.contains(s),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _systemsSelected.add(s);
                              } else {
                                _systemsSelected.remove(s);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_submitted && _systemsSelected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selecciona al menos un sistema',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Descripción
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),

            //const SizedBox(height: 16),

            // Configuración de privacidad
            SwitchListTile(
              title: const Text('Ocultar lista'),
              subtitle: const Text(
                'Acceso mediante código o invitación directa',
              ),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
            // Política de unión
            SwitchListTile(
              title: const Text('Confirmar miembros'),
              subtitle: const Text(
                'Requiere aprobación de un admin para unirse',
              ),
              value: _needsApproval,
              onChanged: (v) => setState(() => _needsApproval = v),
            ),
            const SizedBox(height: 16),

            // Botón de crear
            FilledButton.icon(
              onPressed: _create,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(_saving ? 'Creando...' : 'Crear lista'),
            ),
          ],
        ),
      ),
    );
  }
}
