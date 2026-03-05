import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/list_service.dart';

class SettingsMenu extends StatelessWidget {
  final String listId;

  const SettingsMenu({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Configuración',
      icon: const Icon(Icons.settings),
      onSelected: (value) async {
        if (value != 'delete_group') return;

        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Borrar grupo'),
            content: const Text(
              'Se borrará el grupo, miembros y solicitudes. Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Borrar'),
              ),
            ],
          ),
        );

        if (ok != true) return;

        try {
          await ListService.instance.deleteGroupViaBackend(listId: listId);
          if (!context.mounted) return;

          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Grupo borrado ✅')));
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete_group', child: Text('Borrar grupo')),
      ],
    );
  }
}
