import 'package:flutter/material.dart';
import 'logic/auth_validators.dart';
import 'reset_password_screen.dart';
import 'widgets/auth_email_field.dart';
import 'widgets/auth_submit_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  void _send() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _loading = false);

      const code = '123456';

      Navigator.pushNamed(
        context,
        '/reset',
        arguments: ResetPasswordArgs(
          email: _emailCtrl.text.trim(),
          codeHint: code,
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Ingresa tu correo y te enviaremos un código de recuperación (demo local).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AuthEmailField(
                controller: _emailCtrl,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                text: 'Enviar código (demo)',
                loading: _loading,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
