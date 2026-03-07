import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/services/list_creation_service.dart';
import 'package:sixin_front/core/constants/list_form_constants.dart';
import 'widgets/widgets.dart';

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

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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

      final code = await ListCreationService.instance.createList(
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
        await showAccessCodeDialog(context, code);
        if (!mounted) return;
      }

      messenger.showSnackBar(const SnackBar(content: Text('Lista creada ✅')));

      navigator.pop();
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
            CreateListForm(
              formKey: _formKey,
              submitted: _submitted,
              selectedPlace: _selectedPlace,
              onPlaceChanged: (value) => setState(() => _selectedPlace = value),
              customPlaceCtrl: _customPlaceCtrl,
              date: _date,
              time: _time,
              onPickDate: _pickDate,
              onPickTime: _pickTime,
              totalPriceCtrl: _totalPriceCtrl,
              levelsSelected: _levelsSelected,
              onToggleLevel: (l, selected) {
                setState(() {
                  if (selected) {
                    _levelsSelected.add(l);
                  } else {
                    _levelsSelected.remove(l);
                  }
                });
              },
              systemsSelected: _systemsSelected,
              onToggleSystem: (s, selected) {
                setState(() {
                  if (selected) {
                    _systemsSelected.add(s);
                  } else {
                    _systemsSelected.remove(s);
                  }
                });
              },
              descCtrl: _descCtrl,
            ),

            const SizedBox(height: 16),

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
