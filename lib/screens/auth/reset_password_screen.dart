import 'package:flutter/material.dart';
import 'logic/auth_validators.dart';
import 'widgets/auth_email_field.dart';
import 'widgets/auth_password_field.dart';
import 'widgets/auth_submit_button.dart';

class ResetPasswordArgs {
  final String email;
  final String? codeHint;

  ResetPasswordArgs({required this.email, this.codeHint});
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _codeHint;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as ResetPasswordArgs;

    _emailCtrl.text = args.email;
    _codeHint = args.codeHint;
    if (_codeHint != null) _codeCtrl.text = _codeHint!;
  }

  void _reset() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña restablecida (demo)')),
      );

      Navigator.popUntil(context, ModalRoute.withName('/'));
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restablecer contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              AuthEmailField(
                controller: _emailCtrl,
                validator: null,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                validator: AuthValidators.recoveryCode,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              if (_codeHint != null) Text('Código (demo): $_codeHint'),
              const SizedBox(height: 12),
              AuthPasswordField(
                controller: _passCtrl,
                validator: (v) => AuthValidators.password(
                  v,
                  emptyMessage: 'Ingresa la nueva contraseña',
                ),
                obscureText: _obscure,
                onToggleVisibility: () {
                  setState(() => _obscure = !_obscure);
                },
                labelText: 'Nueva contraseña',
              ),
              const SizedBox(height: 20),
              AuthSubmitButton(
                text: 'Restablecer contraseña',
                loading: _loading,
                onPressed: _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
