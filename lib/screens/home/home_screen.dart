import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final bool isGuest;

  const HomeScreen({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SixIn'),
        actions: [
          if (!isGuest)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ───────────────
              /// WELCOME
              /// ───────────────
              Text(
                isGuest ? 'Bienvenido, invitado' : 'Bienvenido a SixIn',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                isGuest
                    ? 'Estás usando la app en modo invitado. Algunas funciones estarán limitadas.'
                    : 'Has iniciado sesión correctamente.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 32),

              /// ───────────────
              /// MAIN CONTENT PLACEHOLDER
              /// ───────────────
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Contenido principal\n(próximamente)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ───────────────
              /// GUEST CTA
              /// ───────────────
              if (isGuest)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión para desbloquear todo',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
