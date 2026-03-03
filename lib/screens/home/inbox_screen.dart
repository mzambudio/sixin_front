import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../screens.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No hay sesión activa')));
    }

    final invitesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invites')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: invitesStream,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No tienes invitaciones'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final listId = (data['listId'] ?? d.id).toString();
              final listTitle = (data['listTitle'] ?? '(sin título)')
                  .toString();
              final fromUsername = (data['fromUsername'] ?? '—').toString();

              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(listTitle),
                    subtitle: Text('Invitado por $fromUsername'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      final placeholder = SixinList(
                        id: listId,
                        title: listTitle,
                        ownerName: '—',
                        isPublic: false,
                        items: const [],
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListDetailScreen(
                            list: placeholder,
                            isGuest: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
