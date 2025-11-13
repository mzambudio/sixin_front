import 'package:flutter/material.dart';

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
    final args = ModalRoute.of(context)!.settings.arguments as ResetPasswordArgs;

    _emailCtrl.text = args.email;
    _codeHint = args.codeHint;
    if (_codeHint != null) _codeCtrl.text = _codeHint!;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa la nueva contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  String? _validateCode(String? v) {
    if (v == null || v.isEmpty) return 'Ingresa el código';
    return v.length >= 6 ? null : 'Código inválido';
  }

  void _reset() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña restablecida (demo)")),
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
      appBar: AppBar(title: const Text("Restablecer contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Correo",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                validator: _validateCode,
                decoration: const InputDecoration(
                  labelText: "Código",
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
              ),
              if (_codeHint != null)
                Text("Código (demo): $_codeHint"),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                validator: _validatePass,
                decoration: InputDecoration(
                  labelText: "Nueva contraseña",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _reset,
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text("Restablecer contraseña"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
