import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sixin_front/widgets/common/sixin_logo.dart';
import 'package:sixin_front/widgets/common/theme_editor.dart';
import '../../core/services/auth_service.dart';
import '../screens.dart';
import 'logic/auth_validators.dart';
import 'widgets/auth_email_field.dart';
import 'widgets/auth_password_field.dart';
import 'widgets/auth_submit_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.signInWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
      );
      if (!mounted) return;
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-email' => 'El correo no es válido.',
        'user-disabled' => 'Esta cuenta está deshabilitada.',
        'too-many-requests' => 'Demasiados intentos. Prueba más tarde.',
        _ => 'Error al iniciar sesión (${e.code}).',
      };

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al iniciar sesión.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.95);
    final hintColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Editar tema',
                      icon: const Icon(Icons.palette),
                      color: hintColor,
                      onPressed: () => ThemeEditor.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SixinLogo(height: 180),
                const SizedBox(height: 26),
                Text(
                  'Sixin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthEmailField(
                        controller: _emailCtrl,
                        validator: AuthValidators.email,
                      ),
                      const SizedBox(height: 18),
                      AuthPasswordField(
                        controller: _passCtrl,
                        validator: AuthValidators.password,
                        obscureText: _obscure,
                        onToggleVisibility: () {
                          setState(() => _obscure = !_obscure);
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/forgot'),
                          child: Text(
                            '¿Has olvidado tu contraseña?',
                            style: TextStyle(color: hintColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AuthSubmitButton(
                        text: 'Iniciar sesión',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(isGuest: true),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: hintColor.withValues(alpha: 0.22),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: textColor,
                          ),
                          child: Text(
                            'Continuar sin cuenta',
                            style: TextStyle(color: hintColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: hintColor),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'Regístrate',
                              style: TextStyle(color: primary),
                            ),
                          ),
                        ],
                      ),
                    ],
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
