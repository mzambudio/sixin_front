import 'package:flutter/material.dart';
import '../../models/models.dart';

class ListDetailScreen extends StatelessWidget {
  final SixinList list;
  final bool isGuest;

  const ListDetailScreen({
    super.key,
    required this.list,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          if (!isGuest)
            IconButton(
              tooltip: 'Editar lista',
              icon: const Icon(Icons.edit),
              onPressed: () {
                // futuro: editar lista
              },
            ),
        ],
      ),

      body: _ListItemsView(
        items: list.items,
        isGuest: isGuest,
      ),

      floatingActionButton: isGuest
          ? null
          : FloatingActionButton(
              tooltip: 'Añadir item',
              child: const Icon(Icons.add),
              onPressed: () {
                // futuro: añadir item
              },
            ),
    );
  }
}

class _ListItemsView extends StatelessWidget {
  final List<SixinListItem> items;
  final bool isGuest;

  const _ListItemsView({
    required this.items,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isGuest
              ? 'Esta lista no tiene elementos'
              : 'Empieza añadiendo un elemento',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];

        return ListTile(
          title: Text(item.title),
          leading: Icon(
            item.completed ? Icons.check_circle : Icons.circle_outlined,
          ),
          trailing: isGuest
              ? null
              : IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    // futuro: borrar item
                  },
                ),
        );
      },
    );
  }
}
