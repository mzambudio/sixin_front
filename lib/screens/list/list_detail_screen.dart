import 'package:flutter/material.dart';

class ListDetailScreen extends StatelessWidget {
  final String title;
  final bool isGuest;

  const ListDetailScreen({
    super.key,
    required this.title,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: isGuest ? 'Vista solo lectura' : 'Gestionar lista',
            icon: Icon(isGuest ? Icons.visibility : Icons.settings),
            onPressed: isGuest
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gestión de lista (no implementado)'),
                      ),
                    );
                  },
          ),
        ],
      ),

      /// ───────────────
      /// BODY
      /// ───────────────
      body: _ListItems(isGuest: isGuest),

      /// ───────────────
      /// ACTION BUTTON
      /// ───────────────
      floatingActionButton: FloatingActionButton(
        tooltip:
            isGuest ? 'Inicia sesión para añadir items' : 'Añadir item',
        onPressed: isGuest
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Debes iniciar sesión para modificar la lista'),
                  ),
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Añadir item (no implementado)'),
                  ),
                );
              },
        child: Icon(isGuest ? Icons.lock : Icons.add),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// LIST ITEMS
/// ─────────────────────────────────────────────
class _ListItems extends StatelessWidget {
  final bool isGuest;

  const _ListItems({required this.isGuest});

  @override
  Widget build(BuildContext context) {
    // Datos fake
    final items = List.generate(5, (i) => 'Elemento ${i + 1}');

    if (items.isEmpty) {
      return const Center(
        child: Text('Esta lista está vacía'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(items[index]),
            trailing: isGuest
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Eliminar item (no implementado)'),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
