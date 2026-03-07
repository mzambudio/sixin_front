import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/services.dart';
import 'package:sixin_front/core/utils/utils.dart';
import 'package:sixin_front/models/sixin_list.dart';
import 'package:sixin_front/screens/list/detail/list_detail_screen.dart';

class PublicListsTab extends StatelessWidget {
  final bool isGuest;
  const PublicListsTab({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ListQueryService.instance.watchPublicLists(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay listas públicas'));
        }

        final rows = buildDaySections(docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final row = rows[i];

            if (row.isHeader) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  row.headerText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }

            final d = row.doc!;
            final data = d.data();

            final user = FirebaseAuth.instance.currentUser;
            final uid = user?.uid;
            final createdBy = (data['createdBy'] ?? '') as String;
            final isOwner = uid != null && createdBy == uid;

            final title = buildListTitleShort(data);
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: true,
              items: const [],
            );

            final subtitleText = isOwner
                ? 'Creada por ti (${list.ownerName})'
                : 'Creada por ${list.ownerName}';

            return Card(
              child: ListTile(
                title: Text(list.title),
                subtitle: Text(subtitleText),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListDetailScreen(list: list, isGuest: isGuest),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
