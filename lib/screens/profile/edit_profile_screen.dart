import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixin_front/core/services/profile_service.dart';
import 'dart:io';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();

  final List<String> _positions = [];
  XFile? _pickedImage;

  bool _saving = false;
  bool _loadedInitial = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (file == null) return;

    setState(() => _pickedImage = file);
  }

  Future<void> _addPosition() async {
    final ctrl = TextEditingController();
    final pos = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Añadir posición'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Ej: admin'),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );

    if (pos == null) return;

    final cleaned = pos.trim();
    if (cleaned.isEmpty) return;

    setState(() {
      if (!_positions.any((p) => p.toLowerCase() == cleaned.toLowerCase())) {
        _positions.add(cleaned);
        _positions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }
    });
  }

  void _removePosition(String p) {
    setState(() => _positions.remove(p));
  }

  Future<void> _save({
    required String uid,
    required String currentUsername,
    required List<String> currentPositions,
  }) async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final newUsername = _usernameCtrl.text.trim();

      // 1) Username (solo si cambió)
      if (newUsername != currentUsername) {
        await ProfileService.instance.updateUsername(
          uid: uid,
          newUsername: newUsername,
        );
      }

      // 2) Positions (solo si cambió)
      final newPositionsNorm = _positions
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final currNorm = currentPositions
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      bool sameList(List<String> a, List<String> b) {
        final aa = [...a]..sort();
        final bb = [...b]..sort();
        if (aa.length != bb.length) return false;
        for (int i = 0; i < aa.length; i++) {
          if (aa[i] != bb[i]) return false;
        }
        return true;
      }

      if (!sameList(newPositionsNorm, currNorm)) {
        await ProfileService.instance.updatePositions(
          uid: uid,
          positions: newPositionsNorm,
        );
      }

      // 3) Foto (solo si el usuario eligió una)
      if (_pickedImage != null) {
        await ProfileService.instance.uploadProfilePhoto(
          uid: uid,
          file: _pickedImage!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Perfil actualizado ✅')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar perfil')),
        body: const Center(child: Text('No hay sesión activa')),
      );
    }

    final uid = authUser.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ProfileService.instance.watchUserDoc(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error cargando datos'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          final data = doc.data();
          if (!doc.exists || data == null) {
            return const Center(
              child: Text('No existe el documento del usuario'),
            );
          }

          final currentUsername = (data['username'] ?? '') as String;
          final photoUrl = (data['photoUrl'] ?? '') as String;

          final positionsRaw = data['positions'];
          final currentPositions = positionsRaw is List
              ? positionsRaw.map((e) => e.toString()).toList()
              : <String>[];

          // Cargar valores iniciales una sola vez
          if (!_loadedInitial) {
            _loadedInitial = true;
            _usernameCtrl.text = currentUsername;
            _positions
              ..clear()
              ..addAll(currentPositions);
            _positions.sort(
              (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
            );
          }

          return AbsorbPointer(
            absorbing: _saving,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: ClipOval(
                          child: _pickedImage != null
                              ? Image.file(
                                  File(_pickedImage!.path),
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : (photoUrl.trim().isEmpty
                                    ? Center(
                                        child: Text(
                                          currentUsername.isNotEmpty
                                              ? currentUsername[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(fontSize: 32),
                                        ),
                                      )
                                    : Image.network(
                                        photoUrl,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Center(
                                                child: Text(
                                                  currentUsername.isNotEmpty
                                                      ? currentUsername[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                  ),
                                                ),
                                              );
                                            },
                                      )),
                        ),
                      ),

                      FloatingActionButton.small(
                        heroTag: 'pickPhoto',
                        onPressed: _pickPhoto,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      helperText: '3-20 caracteres: letras, números o _',
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      final reg = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
                      if (value.isEmpty) return 'Escribe un username';
                      if (!reg.hasMatch(value)) return 'Formato inválido';
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Positions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addPosition,
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_positions.isEmpty)
                  const Text('— No hay positions —')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _positions
                        .map(
                          (p) => InputChip(
                            label: Text(p.toUpperCase()),
                            onDeleted: () => _removePosition(p),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () => _save(
                    uid: uid,
                    currentUsername: currentUsername,
                    currentPositions: currentPositions,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
