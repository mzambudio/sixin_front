import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/services/list_service.dart';
import 'package:flutter/services.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isPrivate = false;
  bool _needsApproval = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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

  Future<void> _create() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      final uid = user.uid;
      final ownerUsername = await _loadMyUsername(uid);

      final visibility = _isPrivate ? 'private' : 'public';
      final joinPolicy = _needsApproval ? 'approval' : 'open';

      final code = await ListService.instance.createList(
        uid: uid,
        ownerUsername: ownerUsername,
        title: _titleCtrl.text,
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
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Pon un nombre'
                        : null,
                  ),
                  const SizedBox(height: 12),
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

            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Lista privada'),
              subtitle: const Text(
                'No aparece en el feed. Se entra con código.',
              ),
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
            ),
            SwitchListTile(
              title: const Text('Requiere aprobación para unirse'),
              subtitle: const Text('Si no, el usuario entra directamente.'),
              value: _needsApproval,
              onChanged: (v) => setState(() => _needsApproval = v),
            ),

            const SizedBox(height: 16),
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
