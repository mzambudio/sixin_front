import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/auth_service.dart';

enum VolleyPos { oh, o, s, mb, l }

extension VolleyPosX on VolleyPos {
  String get code => name; // "OH", "O", "S", "MB", "L"
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  final Set<VolleyPos> _positions = {};

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v.trim()) ? null : 'Correo inválido';
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa la contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateUsername(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa un nombre de usuario';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    final re = RegExp(r'^[a-zA-Z0-9._-]+$');
    if (!re.hasMatch(value)) {
      return 'Usa solo letras, números, ".", "_" o "-"';
    }
    return null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_positions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una posición.')),
      );
      return;
    }

    setState(() => _loading = true);

    UserCredential? cred;

    try {
      final username = _usernameCtrl.text.trim();
      final usernameLower = username.toLowerCase();

      // 1) Crear usuario en Auth
      cred = await AuthService.instance.signUpWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
      );

      final uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      final usernameRef = db.collection('usernames').doc(usernameLower);
      final userRef = db.collection('users').doc(uid);

      // 2) Transacción: reservar username + crear perfil (atómico)
      await db.runTransaction((tx) async {
        final usernameSnap = await tx.get(usernameRef);

        if (usernameSnap.exists) {
          // Username ya ocupado -> aborta transacción
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'username-taken',
            message: 'Username already taken',
          );
        }

        tx.set(usernameRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(userRef, {
          'username': username,
          'usernameLower': usernameLower,
          'positions': _positions.map((p) => p.code).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // ✅ OK (si usas AuthGate, no necesitas navegar)
      if (!mounted) return;
      Navigator.pop(context); // opcional
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'invalid-email' => 'El correo no es válido.',
        'weak-password' => 'Contraseña demasiado débil (mínimo 6).',
        'operation-not-allowed' =>
          'Email/Password no está activado en Firebase Console.',
        _ => 'Error al registrarse (${e.code}).',
      };

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } on FirebaseException catch (e) {
      // 🔁 Rollback si Auth se creó pero Firestore falló o username estaba pillado
      try {
        await cred?.user?.delete();
      } catch (_) {
        // Si no se puede borrar, al menos cerramos sesión para no quedar medio-logueado
        try {
          await AuthService.instance.signOut();
        } catch (_) {}
      }

      final msg = switch (e.code) {
        'username-taken' => 'Ese nombre de usuario ya está en uso.',
        'permission-denied' => 'Permisos insuficientes en Firestore (rules).',
        _ => e.message ?? 'Error de Firestore (${e.code}).',
      };

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      // 🔁 Rollback por cualquier otro error tras crear Auth
      try {
        await cred?.user?.delete();
      } catch (_) {
        try {
          await AuthService.instance.signOut();
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.95);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Completa tu perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor),
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: 'Correo',
                    labelStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.email_outlined, color: hintColor),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: TextStyle(color: textColor),
                  validator: _validatePass,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _usernameCtrl,
                  style: TextStyle(color: textColor),
                  validator: _validateUsername,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    helperText: 'Así te verán otros jugadores (único).',
                    labelStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.person_outline, color: hintColor),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Posiciones (elige una o varias)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: VolleyPos.values.map((pos) {
                    final selected = _positions.contains(pos);
                    return FilterChip(
                      label: Text(pos.code.toUpperCase()),
                      selected: selected,
                      onSelected: _loading
                          ? null
                          : (v) {
                              setState(() {
                                if (v) {
                                  _positions.add(pos);
                                } else {
                                  _positions.remove(pos);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                ElevatedButton(
                  onPressed: _loading ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Crear cuenta',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
