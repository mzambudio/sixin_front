import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/services.dart';
import 'package:sixin_front/core/settings/settings_controller.dart';
import 'package:sixin_front/screens/profile/member/user_profile_screen.dart';
import 'widgets.dart';

class MembersList extends StatelessWidget {
  final String listId;
  final bool isAdmin;
  final String currentUid;

  const MembersList({
    super.key,
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

        // Widget tile con menú según caso
        Widget tileFor(QueryDocumentSnapshot<Map<String, dynamic>> d) {
          final memberUid = d.id;
          final data = d.data();
          final username = (data['username'] ?? memberUid).toString();
          final role = (data['role'] ?? 'member').toString();
          final isSelf = memberUid == currentUid;
          final preferredRaw = (data['preferredPosition'] ?? '').toString();
          final preferredId = preferredRaw.isEmpty ? null : preferredRaw;

          // Menú disponible:
          // - para admins: degradar a otros admins y (si quieres) expulsar
          final canShowMenu = isAdmin && !isSelf;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ValueListenableBuilder<String>(
              valueListenable: SettingsController.instance.positionsLang,
              builder: (context, langStr, _) {
                final lang = langFromSetting(langStr);
                final text = positionAbbr(preferredId, lang);

                // Solo el propio usuario cambia su preferencia
                if (isSelf) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showPositionPickerDialog(
                        context,
                        currentId: preferredId,
                      );
                      if (picked == null) return;

                      try {
                        await FirebaseFirestore.instance
                            .collection('lists')
                            .doc(listId)
                            .collection('members')
                            .doc(currentUid)
                            .update({'preferredPosition': picked});
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: PositionBadge(text: text, clickable: true),
                  );
                }

                return PositionBadge(text: text);
              },
            ),
            title: Text(isSelf ? '$username (tú)' : username),
            //subtitle: Text(role),
            trailing: canShowMenu
                ? PopupMenuButton<String>(
                    tooltip: 'Acciones',
                    onSelected: (value) async {
                      try {
                        // --- DEGRADAR ADMIN (solo admin sobre otros admins) ---
                        if (value == 'demote_admin') {
                          // seguro: impedir dejar la lista sin admins
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

                          await ListAdminService.instance.demoteAdmin(
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
                          await ListAdminService.instance.makeAdmin(
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

                          await ListAdminService.instance.removeMember(
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
            onTap: isSelf
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(uid: memberUid),
                      ),
                    );
                  },
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
