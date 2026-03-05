import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/list_service.dart';
import 'package:sixin_front/core/utils/utils.dart';
import 'package:sixin_front/models/sixin_list.dart';
import 'package:sixin_front/screens/list/detail/list_detail_screen.dart';

class MyListsTab extends StatelessWidget {
  final String uid;

  const MyListsTab({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ListService.instance.watchMyLists(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aún no estás en ninguna lista'));
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

            final createdBy = (data['createdBy'] ?? '') as String;
            final isOwner = createdBy == uid;

            final title = buildListTitleShort(data); // ✅ lugar + hora
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: (data['visibility'] == 'public'),
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
                          ListDetailScreen(list: list, isGuest: false),
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
