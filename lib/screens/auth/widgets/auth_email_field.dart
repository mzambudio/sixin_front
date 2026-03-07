import 'package:flutter/material.dart';

class AuthEmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String labelText;
  final String? helperText;

  const AuthEmailField({
    super.key,
    required this.controller,
    required this.validator,
    this.readOnly = false,
    this.labelText = 'Correo',
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = theme.colorScheme.primary;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      readOnly: readOnly,
      validator: validator,
      style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.email_outlined, color: hintColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: hintColor.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
