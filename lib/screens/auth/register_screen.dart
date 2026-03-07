import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/services/auth_service.dart';
import 'logic/auth_validators.dart';
import 'widgets/auth_email_field.dart';
import 'widgets/auth_password_field.dart';
import 'widgets/auth_submit_button.dart';

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

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    UserCredential? cred;

    try {
      final username = _usernameCtrl.text.trim();
      final usernameLower = username.toLowerCase();

      cred = await AuthService.instance.signUpWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
      );

      final uid = cred.user!.uid;
      final db = FirebaseFirestore.instance;

      final usernameRef = db.collection('usernames').doc(usernameLower);
      final userRef = db.collection('users').doc(uid);

      await db.runTransaction((tx) async {
        final usernameSnap = await tx.get(usernameRef);

        if (usernameSnap.exists) {
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
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
        'invalid-email' => 'El correo no es válido.',
        'weak-password' => 'Contraseña demasiado débil (mínimo 6).',
        'operation-not-allowed' =>
          'Email/Password no está activado en Firebase Console.',
        _ => 'Error al registrarse (${e.code}).',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on FirebaseException catch (e) {
      try {
        await cred?.user?.delete();
      } catch (_) {
        try {
          await AuthService.instance.signOut();
        } catch (_) {}
      }

      final msg = switch (e.code) {
        'username-taken' => 'Ese nombre de usuario ya está en uso.',
        'permission-denied' => 'Permisos insuficientes en Firestore (rules).',
        _ => e.message ?? 'Error de Firestore (${e.code}).',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      try {
        await cred?.user?.delete();
      } catch (_) {
        try {
          await AuthService.instance.signOut();
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.95);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);

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
                AuthEmailField(
                  controller: _emailCtrl,
                  validator: AuthValidators.email,
                ),
                const SizedBox(height: 16),
                AuthPasswordField(
                  controller: _passCtrl,
                  validator: AuthValidators.password,
                  obscureText: _obscure,
                  onToggleVisibility: () {
                    setState(() => _obscure = !_obscure);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameCtrl,
                  style: TextStyle(color: textColor),
                  validator: AuthValidators.username,
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    helperText: 'Así te verán otros jugadores (único).',
                    labelStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.person_outline, color: hintColor),
                  ),
                ),
                const SizedBox(height: 22),
                AuthSubmitButton(
                  text: 'Crear cuenta',
                  loading: _loading,
                  onPressed: _submitRegister,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
