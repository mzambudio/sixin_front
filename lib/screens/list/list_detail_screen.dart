import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sixin_front/core/services/list_service.dart';

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

      body: _ListDetailBody(listId: list.id, isGuest: isGuest),

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

class _ListDetailBody extends StatelessWidget {
  final String listId;
  final bool isGuest;

  const _ListDetailBody({required this.listId, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final listDocStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: listDocStream,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = snap.data!;
        final data = doc.data();
        if (!doc.exists || data == null) {
          return const Center(child: Text('La lista no existe'));
        }

        final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
        final createdBy = (data['createdBy'] ?? '') as String;
        final adminsRaw = data['admins'];
        final admins = adminsRaw is List
            ? adminsRaw.map((e) => e.toString()).toList()
            : <String>[];

        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? '';

        final isAdmin =
            uid.isNotEmpty && (uid == createdBy || admins.contains(uid));
        final showRequests = !isGuest && isAdmin && joinPolicy == 'approval';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _MembersList(listId: listId, isAdmin: isAdmin, currentUid: uid),

            if (showRequests) ...[
              const SizedBox(height: 24),
              Text(
                'Solicitudes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _RequestsList(listId: listId),
            ],

            if (!isGuest &&
                uid.isNotEmpty &&
                joinPolicy == 'approval' &&
                !isAdmin) ...[
              const SizedBox(height: 12),
              _MyRequestStatus(listId: listId, uid: uid),
            ],
          ],
        );
      },
    );
  }
}

class _MembersList extends StatelessWidget {
  final String listId;
  final bool isAdmin;
  final String currentUid;

  const _MembersList({
    required this.listId,
    required this.isAdmin,
    required this.currentUid,
  });

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
        if (snap.hasError) return Text('Error: ${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('Aún no hay miembros');

        return Column(
          children: docs.map((d) {
            final memberUid = d.id;
            final data = d.data();
            final username = (data['username'] ?? memberUid).toString();
            final role = (data['role'] ?? 'member').toString();

            final canKick = isAdmin && memberUid != currentUid;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text(username),
              subtitle: Text(role),
              trailing: canKick
                  ? IconButton(
                      tooltip: 'Expulsar',
                      icon: const Icon(Icons.person_remove),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Expulsar miembro'),
                            content: Text(
                              '¿Quieres expulsar a $username de la lista?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Expulsar'),
                              ),
                            ],
                          ),
                        );

                        if (ok != true) return;

                        try {
                          await ListService.instance.removeMember(
                            listId: listId,
                            targetUid: memberUid,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$username expulsado')),
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
                    )
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final String listId;
  const _RequestsList({required this.listId});

  @override
  Widget build(BuildContext context) {
    final requestsStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .orderBy('requestedAt', descending: false)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: requestsStream,
      builder: (context, snap) {
        if (snap.hasError) return Text('Error: ${snap.error}');
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('No hay solicitudes pendientes');

        return Column(
          children: docs.map((d) {
            final requesterUid = d.id;
            final data = d.data();
            final username = (data['username'] ?? requesterUid).toString();

            return Card(
              child: ListTile(
                leading: const Icon(Icons.person_add),
                title: Text(username),
                subtitle: const Text('Pendiente'),
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
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MyRequestStatus extends StatelessWidget {
  final String listId;
  final String uid;

  const _MyRequestStatus({required this.listId, required this.uid});

  @override
  Widget build(BuildContext context) {
    final reqDocStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .doc(uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: reqDocStream,
      builder: (context, snap) {
        if (snap.hasError) return Text('Error: ${snap.error}');
        if (!snap.hasData) return const SizedBox.shrink();

        final doc = snap.data!;
        if (!doc.exists) return const SizedBox.shrink(); // no hay solicitud

        return Card(
          child: ListTile(
            leading: const Icon(Icons.hourglass_top),
            title: const Text('Solicitud pendiente'),
            subtitle: const Text('Esperando aprobación del admin'),
            trailing: TextButton(
              onPressed: () async {
                try {
                  await ListService.instance.cancelJoinRequest(
                    listId: listId,
                    uid: uid,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud cancelada')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Cancelar'),
            ),
          ),
        );
      },
    );
  }
}
