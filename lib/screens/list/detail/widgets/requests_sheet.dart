import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/list_service.dart';

class RequestsSheet extends StatelessWidget {
  final String listId;

  const RequestsSheet({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    final requestsStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .orderBy('requestedAt', descending: false)
        .snapshots();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Solicitudes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: requestsStream,
                builder: (context, snap) {
                  if (snap.hasError) return Text('Error: ${snap.error}');
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No hay solicitudes pendientes'),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final requesterUid = d.id;
                      final data = d.data();
                      final username = (data['username'] ?? requesterUid)
                          .toString();

                      return ListTile(
                        leading: const Icon(Icons.person_add),
                        title: Text(username),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Rechazar',
                              icon: const Icon(Icons.close),
                              onPressed: () async {
                                try {
                                  await ListService.instance.rejectRequest(
                                    listId: listId,
                                    requesterUid: requesterUid,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Solicitud rechazada'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                            IconButton(
                              tooltip: 'Aprobar',
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                try {
                                  await ListService.instance.approveRequest(
                                    listId: listId,
                                    requesterUid: requesterUid,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Usuario aprobado ✅'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
