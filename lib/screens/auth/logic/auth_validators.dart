class AuthValidators {
  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _usernameRe = RegExp(r'^[a-zA-Z0-9._-]+$');

  static String? email(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa tu correo';
    return _emailRe.hasMatch(value) ? null : 'Correo inválido';
  }

  static String? password(
    String? v, {
    String emptyMessage = 'Ingresa la contraseña',
  }) {
    final value = v ?? '';
    if (value.isEmpty) return emptyMessage;
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? username(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Ingresa un nombre de usuario';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    if (!_usernameRe.hasMatch(value)) {
      return 'Usa solo letras, números, ".", "_" o "-"';
    }
    return null;
  }

  static String? recoveryCode(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Ingresa el código';
    return value.length >= 6 ? null : 'Código inválido';
  }
}
