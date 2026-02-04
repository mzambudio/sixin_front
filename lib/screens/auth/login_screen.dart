import 'package:flutter/material.dart';
import '../../widgets/common/theme_editor.dart';
import '../screens.dart';

/// ─────────────────────────────────────────────
/// LOGIN SCREEN (STATEFUL WIDGET)
/// ─────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// ─────────────────────────────────────────────
/// STATE DEL LOGIN
/// ─────────────────────────────────────────────
class _LoginScreenState extends State<LoginScreen> {
  /// ───────────────
  /// FORM & CONTROLLERS
  /// ───────────────
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  /// ───────────────
  /// UI STATE
  /// ───────────────
  bool _obscure = true; // mostrar/ocultar contraseña
  bool _loading = false; // estado de carga del botón

  /// ───────────────
  /// VALIDACIONES
  /// ───────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v) ? null : 'Correo inválido';
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa la contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// ───────────────
  /// SUBMIT / LOGIN ACTION
  /// ───────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(isGuest: false),
        ), // Acceso completo
      );
    });
  }

  /// ───────────────
  /// CLEANUP
  /// ───────────────
  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// ─────────────────────────────────────────────
  /// BUILD UI
  /// ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    /// ───────────────
    /// THEME SHORTCUTS
    /// ───────────────
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.95);
    final hintColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/images/sixin_white.png'
        : 'assets/images/sixin_black.png';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// ───────────────
                /// TOP ACTIONS (THEME)
                /// ───────────────
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

                /// ───────────────
                /// LOGO & TITLE
                /// ───────────────
                Image(image: AssetImage(logoAsset), height: 180),
                const SizedBox(height: 26),
                Text(
                  'SixIn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 36),

                /// ───────────────
                /// LOGIN FORM
                /// ───────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      /// ───────────────
                      /// EMAIL FIELD
                      /// ───────────────
                      TextFormField(
                        controller: _emailCtrl,
                        autofillHints: null,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        validator: _validateEmail,
                        decoration: InputDecoration(
                          labelText: 'Correo',
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: hintColor,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: hintColor.withOpacity(0.28),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// ───────────────
                      /// PASSWORD FIELD
                      /// ───────────────
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: TextStyle(color: textColor),
                        validator: _validatePass,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: hintColor),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: hintColor,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: hintColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: hintColor.withOpacity(0.28),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ───────────────
                      /// FORGOT PASSWORD
                      /// ───────────────
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

                      /// ───────────────
                      /// LOGIN BUTTON
                      /// ───────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? () {} : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _loading
                                ? const SizedBox(
                                    key: ValueKey('loading'),
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    key: ValueKey('text'),
                                    'Iniciar sesión',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ───────────────
                      /// GUEST ACCESS
                      /// ───────────────
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
                              color: hintColor.withOpacity(0.22),
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

                      /// ───────────────
                      /// REGISTER CTA
                      /// ───────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta?',
                            style: TextStyle(color: hintColor),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Registro no implementado en demo',
                                  ),
                                ),
                              );
                            },
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
