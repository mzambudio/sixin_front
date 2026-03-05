import 'package:flutter/material.dart';

class HomeFab extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onJoinByCode;
  final VoidCallback onCreateList;
  final VoidCallback onLoginRequired;

  const HomeFab({
    super.key,
    required this.isGuest,
    required this.onJoinByCode,
    required this.onCreateList,
    required this.onLoginRequired,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return FloatingActionButton(
        onPressed: onLoginRequired,
        tooltip: 'Inicia sesión para crear o unirte a listas',
        child: const Icon(Icons.lock),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        
        // FAB: introducir código (llave) - arriba
        Padding(
          padding: const EdgeInsets.only(bottom: 72),
          child: FloatingActionButton(
            heroTag: 'fab_code',
            tooltip: 'Introducir código',
            onPressed: onJoinByCode,
            child: const Icon(Icons.key),
          ),
        ),

        // FAB: crear lista (add) - abajo
        FloatingActionButton(
          heroTag: 'fab_create',
          tooltip: 'Crear lista',
          onPressed: onCreateList,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
