import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/core/services/services.dart';

class JoinBar extends StatelessWidget {
  final String listId;
  final bool isGuest;

  final String uid;

  final bool isMember;
  final bool isOnlyAdmin;
  final bool isOnlyMember; // NEW
  final bool wasAdmin;

  final String joinPolicy;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? inviteDocStream;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? requestDocStream;

  const JoinBar({
    super.key,
    required this.listId,
    required this.isGuest,
    required this.uid,
    required this.isMember,
    required this.isOnlyAdmin,
    required this.isOnlyMember, // NEW
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
                isOnlyMember: isOnlyMember, // NEW
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
  final bool isOnlyMember; // NEW
  final bool wasAdmin;

  const _LeaveButton({
    required this.listId,
    required this.uid,
    required this.isOnlyAdmin,
    required this.isOnlyMember, // NEW
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
        if (isOnlyMember) {
          final ok = await _confirm(
            context,
            title: 'Borrar lista',
            message:
                'Eres el único miembro. Si sales, la lista se borrará. ¿Continuar?',
            okText: 'Borrar',
          );
          if (!ok) return;

          try {
            await ListBackendService.instance.deleteGroupViaBackend(
              listId: listId,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
            _snack(context, 'Lista borrada ✅');
          } catch (e) {
            if (!context.mounted) return;
            _snack(context, 'Error: $e');
          }
          return;
        }

        if (isOnlyAdmin) {
          _snack(
            context,
            'Eres el único admin. Designa a otro admin antes de salir.',
          );
          return;
        }

        final ok = await _confirm(
          context,
          title: 'Salir del grupo',
          message: '¿Quieres salir de este grupo?',
          okText: 'Salir',
        );
        if (!ok) return;

        try {
          await ListMembershipService.instance.leaveList(
            listId: listId,
            uid: uid,
            wasAdmin: wasAdmin,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
          _snack(context, 'Has salido del grupo');
        } catch (e) {
          if (!context.mounted) return;
          _snack(context, 'Error: $e');
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
                  onPressed: () => _runAction(
                    context,
                    () => ListInvitationService.instance.rejectInvite(
                      listId: listId,
                      uid: uid,
                    ),
                    successMsg: 'Invitación rechazada',
                    onSuccess: () => Navigator.pop(context),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Aceptar invitación'),
                  onPressed: () => _runAction(
                    context,
                    () => ListInvitationService.instance.acceptInvite(
                      listId: listId,
                      uid: uid,
                    ),
                    successMsg: 'Te has unido ✅',
                  ),
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
                  onPressed: () => _runAction(
                    context,
                    () => ListMembershipService.instance.cancelJoinRequest(
                      listId: listId,
                      uid: uid,
                    ),
                    successMsg: 'Solicitud cancelada',
                  ),
                );
              }

              return FilledButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Solicitar unirme'),
                onPressed: () => _runAction(
                  context,
                  () => ListMembershipService.instance.requestJoin(
                    listId: listId,
                    uid: uid,
                  ),
                  successMsg: 'Solicitud enviada ✅',
                ),
              );
            },
          );
        }

        // Si joinPolicy == 'open'
        return FilledButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Unirme'),
          onPressed: () => _runAction(
            context,
            () => ListMembershipService.instance.joinList(
              listId: listId,
              uid: uid,
            ),
            successMsg: 'Te has unido ✅',
          ),
        );
      },
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String okText,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(okText),
        ),
      ],
    ),
  );
  return ok == true;
}

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> _runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? successMsg,
  VoidCallback? onSuccess,
}) async {
  try {
    await action();
    if (!context.mounted) return;
    if (successMsg != null) _snack(context, successMsg);
    onSuccess?.call();
  } catch (e) {
    if (!context.mounted) return;
    _snack(context, 'Error: $e');
  }
}
