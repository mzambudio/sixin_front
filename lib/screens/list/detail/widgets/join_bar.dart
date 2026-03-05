import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/services/list_service.dart';

class JoinBar extends StatelessWidget {
  final String listId;
  final bool isGuest;

  final String uid;

  final bool isMember;
  final bool isOnlyAdmin;
  final bool wasAdmin; // el rol del usuario actual en ESTA lista (isAdmin)

  final String joinPolicy; // 'open' | 'approval'
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? inviteDocStream;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? requestDocStream;

  const JoinBar({
    super.key,
    required this.listId,
    required this.isGuest,
    required this.uid,
    required this.isMember,
    required this.isOnlyAdmin,
    required this.wasAdmin,
    required this.joinPolicy,
    required this.inviteDocStream,
    required this.requestDocStream,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: isMember
            ? _LeaveButton(
                listId: listId,
                uid: uid,
                isOnlyAdmin: isOnlyAdmin,
                wasAdmin: wasAdmin,
              )
            : _JoinArea(
                listId: listId,
                uid: uid,
                joinPolicy: joinPolicy,
                inviteDocStream: inviteDocStream,
                requestDocStream: requestDocStream,
              ),
      ),
    );
  }
}

class _LeaveButton extends StatelessWidget {
  final String listId;
  final String uid;
  final bool isOnlyAdmin;
  final bool wasAdmin;

  const _LeaveButton({
    required this.listId,
    required this.uid,
    required this.isOnlyAdmin,
    required this.wasAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.exit_to_app),
      label: const Text('Salir del grupo'),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
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
            content: const Text('¿Quieres salir de este grupo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
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
            wasAdmin: wasAdmin,
          );

          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Has salido del grupo')));
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
    );
  }
}

class _JoinArea extends StatelessWidget {
  final String listId;
  final String uid;
  final String joinPolicy;

  final Stream<DocumentSnapshot<Map<String, dynamic>>>? inviteDocStream;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? requestDocStream;

  const _JoinArea({
    required this.listId,
    required this.uid,
    required this.joinPolicy,
    required this.inviteDocStream,
    required this.requestDocStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                      await ListService.instance.rejectInvite(
                        listId: listId,
                        uid: uid,
                      );
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitación rechazada')),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                      await ListService.instance.acceptInvite(
                        listId: listId,
                        uid: uid,
                      );
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Te has unido ✅')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                ),
              ),
            ],
          );
        }

        if (joinPolicy == 'approval' && requestDocStream != null) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: requestDocStream,
            builder: (context, reqSnap) {
              final pending = reqSnap.data?.exists == true;

              if (pending) {
                return FilledButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar solicitud'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () async {
                    try {
                      await ListService.instance.cancelJoinRequest(
                        listId: listId,
                        uid: uid,
                      );
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Solicitud cancelada')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                );
              }

              return FilledButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Solicitar unirme'),
                onPressed: () async {
                  try {
                    await ListService.instance.requestJoin(
                      listId: listId,
                      uid: uid,
                    );
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud enviada ✅')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              );
            },
          );
        }

        // joinPolicy == 'open'
        return FilledButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Unirme'),
          onPressed: () async {
            try {
              await ListService.instance.joinList(listId: listId, uid: uid);
              if (!context.mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Te has unido ✅')));
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          },
        );
      },
    );
  }
}
