import 'package:flutter/material.dart';
import '../../widgets/common/theme_editor.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home (demo)'),
        actions: [
          IconButton(
            onPressed: () => ThemeEditor.show(context),
            icon: const Icon(Icons.palette),
            tooltip: 'Editar tema',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Has iniciado sesión correctamente (demo).\n\nPulsa el icono de paleta para editar el tema.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
