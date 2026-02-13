import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      body: _MembersView(listId: list.id),

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

class _MembersView extends StatelessWidget {
  final String listId;
  const _MembersView({required this.listId});

  @override
  Widget build(BuildContext context) {
    final membersStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('members')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: membersStream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aún no hay miembros'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final username = (data['username'] ?? docs[i].id).toString();
            final role = (data['role'] ?? 'member').toString();

            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(username),
              subtitle: Text(role),
            );
          },
        );
      },
    );
  }
}
