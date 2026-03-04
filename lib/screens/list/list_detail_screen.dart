import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sixin_front/core/services/list_service.dart';
import 'package:flutter/services.dart';

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

        final place = (data['place'] ?? '').toString();

        final startAtRaw = data['startAt'];
        final startAt = startAtRaw is Timestamp ? startAtRaw.toDate() : null;

        String formatTime(DateTime d) =>
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

        final appTitle = (place.isNotEmpty && startAt != null)
            ? '$place • ${formatTime(startAt.toLocal())}'
            : (place.isNotEmpty ? place : list.title);

        final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
        final visibility = (data['visibility'] ?? 'public') as String;
        final joinCode = (data['joinCode'] ?? '').toString();
        final isPrivate = visibility == 'private';
        final adminsRaw = data['admins'];
        final admins = adminsRaw is List
            ? adminsRaw.map((e) => e.toString()).toList()
            : <String>[];

        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid ?? '';
        final isAdmin = uid.isNotEmpty && admins.contains(uid);
        final isOnlyAdmin = isAdmin && admins.length == 1;
        final canSeeRequests = !isGuest && isAdmin && joinPolicy == 'approval';

        final memberUidsRaw = data['memberUids'];
        final memberUids = memberUidsRaw is List
            ? memberUidsRaw.map((e) => e.toString()).toList()
            : <String>[];

        final isMember = uid.isNotEmpty && memberUids.contains(uid);

        final requestDocStream =
            (isGuest || uid.isEmpty || joinPolicy != 'approval')
            ? null
            : FirebaseFirestore.instance
                  .collection('lists')
                  .doc(listId)
                  .collection('requests')
                  .doc(uid)
                  .snapshots();

        final inviteDocStream = (isGuest || uid.isEmpty)
            ? null
            : FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('invites')
                  .doc(listId)
                  .snapshots();

        return Scaffold(
          appBar: AppBar(
            title: Text(appTitle),
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

              // Configuración (solo admin)
              if (!isGuest && isAdmin)
                PopupMenuButton<String>(
                  tooltip: 'Configuración',
                  icon: const Icon(Icons.settings),
                  onSelected: (value) async {
                    // Borrar grupo
                    if (value == 'delete_group') {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Borrar grupo'),
                          content: const Text(
                            'Se borrará el grupo, miembros y solicitudes. Esta acción no se puede deshacer.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Borrar'),
                            ),
                          ],
                        ),
                      );

                      if (ok != true) return;

                      try {
                        await ListService.instance.deleteGroupViaBackend(
                          listId: listId,
                        );

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Grupo borrado ✅')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete_group',
                      child: Text('Borrar grupo'),
                    ),
                  ],
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

          // Invitar miembros (invitación directa o por código)
          floatingActionButton: (isGuest || !isAdmin)
              ? null
              : FloatingActionButton(
                  tooltip: 'Invitar miembros',
                  child: const Icon(Icons.person_add),
                  onPressed: () async {
                    final ctrl = TextEditingController();

                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Invitar'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Mostrar código de acceso (solo si es privado)
                            if (isPrivate) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      joinCode.isEmpty ? '—' : joinCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Copiar código',
                                    icon: const Icon(Icons.copy),
                                    onPressed: joinCode.isEmpty
                                        ? null
                                        : () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: joinCode),
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Código copiado ✅',
                                                ),
                                              ),
                                            );
                                          },
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 10),
                            ],
                            // Invitar por username
                            TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de usuario',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              final input = ctrl.text.trim();
                              if (input.isEmpty) return;

                              try {
                                await ListService.instance.inviteByUsername(
                                  listId: listId,
                                  usernameInput: input,
                                );
                                if (!context.mounted) return;

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitación enviada ✅'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            child: const Text('Enviar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          bottomNavigationBar: isGuest
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: isMember
                        ? FilledButton.icon(
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Salir del grupo'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            ),
                            onPressed: () async {
                              if (isOnlyAdmin) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Eres el único admin. Designa a otro admin antes de salir.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Salir del grupo'),
                                  content: const Text(
                                    '¿Quieres salir de este grupo?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Salir'),
                                    ),
                                  ],
                                ),
                              );

                              if (ok != true) return;

                              try {
                                await ListService.instance.leaveList(
                                  listId: listId,
                                  uid: uid,
                                  wasAdmin: isAdmin,
                                );

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Has salido del grupo'),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          )
                        : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: inviteDocStream,
                            builder: (context, invSnap) {
                              final hasInvite = invSnap.data?.exists == true;

                              if (hasInvite) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.close),
                                        label: const Text('Rechazar'),
                                        onPressed: () async {
                                          try {
                                            await ListService.instance
                                                .rejectInvite(
                                                  listId: listId,
                                                  uid: uid,
                                                );

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Invitación rechazada',
                                                ),
                                              ),
                                            );
                                            Navigator.pop(context);
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: const Text('Aceptar invitación'),
                                        onPressed: () async {
                                          try {
                                            await ListService.instance
                                                .acceptInvite(
                                                  listId: listId,
                                                  uid: uid,
                                                );

                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Te has unido ✅'),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }

                              if (joinPolicy == 'approval' &&
                                  requestDocStream != null) {
                                return StreamBuilder<
                                  DocumentSnapshot<Map<String, dynamic>>
                                >(
                                  stream: requestDocStream,
                                  builder: (context, reqSnap) {
                                    final pending =
                                        reqSnap.data?.exists == true;

                                    if (pending) {
                                      return FilledButton.icon(
                                        icon: const Icon(Icons.cancel),
                                        label: const Text('Cancelar solicitud'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onError,
                                        ),
                                        onPressed: () async {
                                          try {
                                            await ListService.instance
                                                .cancelJoinRequest(
                                                  listId: listId,
                                                  uid: uid,
                                                );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Solicitud cancelada',
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    }

                                    return FilledButton.icon(
                                      icon: const Icon(Icons.send),
                                      label: const Text('Solicitar unirme'),
                                      onPressed: () async {
                                        try {
                                          await ListService.instance
                                              .requestJoin(
                                                listId: listId,
                                                uid: uid,
                                              );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Solicitud enviada ✅',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                );
                              }

                              return FilledButton.icon(
                                icon: const Icon(Icons.login),
                                label: const Text('Unirme'),
                                onPressed: () async {
                                  try {
                                    await ListService.instance.joinList(
                                      listId: listId,
                                      uid: uid,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Te has unido ✅'),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ),
        );
      },
    );
  }
}

// Hoja modal que muestra las solicitudes pendientes, con opción a aprobar/rechazar (solo para admins)
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

// Botón de solicitudes con badge que muestra el número de solicitudes pendientes
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

// Widget que muestra la lista de miembros, separados por admins y miembros normales, con opciones según el rol del usuario actual
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
          // - para admins: degradar a otros admins y (si quieres) expulsar
          final canShowMenu = isAdmin && !isSelf;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(role == 'admin' ? Icons.shield : Icons.person),
            title: Text(isSelf ? '$username (tú)' : username),
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

                      // Otros: solo admins pueden ver menú
                      if (!isAdmin) return items;

                      // Si es admin -> opciones según role del objetivo
                      if (role == 'admin') {
                        items.add(
                          const PopupMenuItem(
                            value: 'demote_admin',
                            child: Text('Descartar como admin'),
                          ),
                        );
                      } else {
                        items.add(
                          const PopupMenuItem(
                            value: 'make_admin',
                            child: Text('Designar como admin'),
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
