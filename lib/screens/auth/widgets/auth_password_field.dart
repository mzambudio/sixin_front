import 'package:flutter/material.dart';

class AuthPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String labelText;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.validator,
    required this.obscureText,
    required this.onToggleVisibility,
    this.labelText = 'Contraseña',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final primary = theme.colorScheme.primary;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.95),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.lock_outline, color: hintColor),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: hintColor,
          ),
        ),
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
