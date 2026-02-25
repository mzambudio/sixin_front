import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sixin_front/core/services/list_service.dart';

class ListDetailScreen extends StatefulWidget {
  final SixinList list;
  final bool isGuest;

  const ListDetailScreen({
    super.key,
    required this.list,
    required this.isGuest,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _editMode = false;

  void _toggleEditMode() {
    setState(() => _editMode = !_editMode);
  }

  @override
  Widget build(BuildContext context) {
    final listId = widget.list.id;
    final isGuest = widget.isGuest;

    final listDocStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: listDocStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.list.title)),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.list.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data!;
        final data = doc.data();
        if (!doc.exists || data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.list.title)),
            body: const Center(child: Text('La lista no existe')),
          );
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
        final canSeeRequests =
            !widget.isGuest && isAdmin && joinPolicy == 'approval';

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.list.title),
            actions: [
              // Editar lista
              if (!isGuest)
                IconButton(
                  tooltip: _editMode ? 'Salir de edición' : 'Editar lista',
                  icon: Icon(_editMode ? Icons.check : Icons.edit),
                  onPressed: _toggleEditMode,
                ),

              // Solicitudes
              if (canSeeRequests)
                _RequestsBadgeButton(
                  listId: listId,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => _RequestsSheet(listId: listId),
                    );
                  },
                ),
            ],
          ),

          // Body: miembros
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _MembersList(listId: listId, isAdmin: isAdmin, currentUid: uid),
            ],
          ),

          floatingActionButton: widget.isGuest
              ? null
              : FloatingActionButton(
                  tooltip: 'Invitar miembros',
                  child: const Icon(Icons.person_add),
                  onPressed: () {
                    // futuro: invitar usuario por username o email
                  },
                ),
        );
      },
    );
  }
}

class _RequestsSheet extends StatelessWidget {
  final String listId;

  const _RequestsSheet({required this.listId});

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

class _RequestsBadgeButton extends StatelessWidget {
  final String listId;
  final VoidCallback onTap;

  const _RequestsBadgeButton({required this.listId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final countStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: countStream,
      builder: (context, snap) {
        final count = snap.data?.size ?? 0;

        return IconButton(
          tooltip: 'Solicitudes',
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.inbox),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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

        // ✅ separar
        final admins = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final members = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final d in docs) {
          final role = (d.data()['role'] ?? 'member').toString();
          if (role == 'admin') {
            admins.add(d);
          } else {
            members.add(d);
          }
        }

        // (opcional) ordenar por username
        int byUsername(a, b) {
          final ua = (a.data()['username'] ?? a.id).toString().toLowerCase();
          final ub = (b.data()['username'] ?? b.id).toString().toLowerCase();
          return ua.compareTo(ub);
        }

        admins.sort(byUsername);
        members.sort(byUsername);

        Widget tileFor(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final memberUid = d.id;
          final data = d.data();
          final username = (data['username'] ?? memberUid).toString();
          final role = (data['role'] ?? 'member').toString();

          final canKick = isAdmin && memberUid != currentUid;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(role == 'admin' ? Icons.shield : Icons.person),
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
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  )
                : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ADMINS ---
            Text('Admins', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...admins.map(tileFor),

            const SizedBox(height: 16),

            // --- MIEMBROS ---
            Text('Miembros', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            if (members.isEmpty) const Text('—') else ...members.map(tileFor),
          ],
        );
      },
    );
  }
}
