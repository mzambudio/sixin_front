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
    final listId = list.id;

    final listDocStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: listDocStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(list.title)),
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(list.title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data!;
        final data = doc.data();
        if (!doc.exists || data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(list.title)),
            body: const Center(child: Text('La lista no existe')),
          );
        }

        final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
        final adminsRaw = data['admins'];
        final admins = adminsRaw is List
            ? adminsRaw.map((e) => e.toString()).toList()
            : <String>[];

        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? '';

        final isAdmin = uid.isNotEmpty && admins.contains(uid);

        final canSeeRequests = !isGuest && isAdmin && joinPolicy == 'approval';

        return Scaffold(
          appBar: AppBar(
            title: Text(list.title),
            actions: [
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

          floatingActionButton: isGuest
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
  final bool isAdmin; // si el usuario actual es admin (según doc lists)
  final String currentUid; // uid del usuario actual

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
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Text('Aún no hay miembros');

        // Separar admins / miembros
        final adminDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final memberDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        for (final d in docs) {
          final role = (d.data()['role'] ?? 'member').toString();
          if (role == 'admin') {
            adminDocs.add(d);
          } else {
            memberDocs.add(d);
          }
        }

        // Ordenar por username
        int byUsername(a, b) {
          final ua = (a.data()['username'] ?? a.id).toString().toLowerCase();
          final ub = (b.data()['username'] ?? b.id).toString().toLowerCase();
          return ua.compareTo(ub);
        }

        adminDocs.sort(byUsername);
        memberDocs.sort(byUsername);

        // Para saber si el usuario actual es el ÚNICO admin (usamos lo que hay en members)
        final adminUids = adminDocs.map((d) => d.id).toList();
        final isCurrentUserAdmin = adminUids.contains(currentUid);
        final isOnlyAdmin = isCurrentUserAdmin && adminUids.length == 1;

        // Widget tile con menú según caso
        Widget tileFor(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final memberUid = d.id;
          final data = d.data();
          final username = (data['username'] ?? memberUid).toString();
          final role = (data['role'] ?? 'member').toString();
          final isSelf = memberUid == currentUid;

          // Menú disponible:
          // - siempre para el propio usuario (salir)
          // - para admins: degradar a otros admins y (si quieres) expulsar
          final canShowMenu =
              isSelf || (isAdmin && !isSelf); // admin puede actuar sobre otros

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(role == 'admin' ? Icons.shield : Icons.person),
            title: Text(username),
            subtitle: Text(role),
            trailing: canShowMenu
                ? PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    onSelected: (value) async {
                      try {
                        // --- SALIR (solo self) ---
                        if (value == 'leave') {
                          if (isOnlyAdmin) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Eres el único admin. Designa a otro admin antes de salir.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          
                          await ListService.instance.leaveList(
                            listId: listId,
                            uid: currentUid,
                            wasAdmin: role == 'admin',
                          );

                          if (context.mounted) {
                            Navigator.pop(context); // sales del detalle
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Has salido del grupo'),
                              ),
                            );
                          }
                          return;
                        }

                        // --- DEGRADAR ADMIN (solo admin sobre otros admins) ---
                        if (value == 'demote_admin') {
                          // opcional: impedir dejar la lista sin admins
                          if (role == 'admin' && adminUids.length == 1) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Debe quedar al menos un admin.',
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          await ListService.instance.demoteAdmin(
                            listId: listId,
                            targetUid: memberUid,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$username ya no es admin'),
                              ),
                            );
                          }
                          return;
                        }

                        // --- HACER ADMIN (solo admin sobre miembros) ---
                        if (value == 'make_admin') {
                          await ListService.instance.makeAdmin(
                            listId: listId,
                            targetUid: memberUid,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$username ahora es admin'),
                              ),
                            );
                          }
                          return;
                        }

                        // --- EXPULSAR (solo admin sobre otros) ---
                        if (value == 'kick') {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Expulsar miembro'),
                              content: Text(
                                '¿Quieres expulsar a $username de la lista?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
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

                          await ListService.instance.removeMember(
                            listId: listId,
                            targetUid: memberUid,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$username expulsado')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];

                      // Self: solo "Salir"
                      if (isSelf) {
                        items.add(
                          const PopupMenuItem(
                            value: 'leave',
                            child: Text('Salir del grupo'),
                          ),
                        );
                        return items;
                      }

                      // Otros: solo admins pueden ver menú
                      if (!isAdmin) return items;

                      // Si es admin -> opciones según role del objetivo
                      if (role == 'admin') {
                        items.add(
                          const PopupMenuItem(
                            value: 'demote_admin',
                            child: Text('Dejar de ser admin'),
                          ),
                        );
                      } else {
                        items.add(
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Text('Hacer admin'),
                          ),
                        );
                      }

                      items.add(const PopupMenuDivider());
                      items.add(
                        const PopupMenuItem(
                          value: 'kick',
                          child: Text('Expulsar'),
                        ),
                      );

                      return items;
                    },
                  )
                : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admins', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...adminDocs.map(tileFor),

            const SizedBox(height: 16),

            Text('Miembros', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            if (memberDocs.isEmpty)
              const Text('—')
            else
              ...memberDocs.map(tileFor),
          ],
        );
      },
    );
  }
}
