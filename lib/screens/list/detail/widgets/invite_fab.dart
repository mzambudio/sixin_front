import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixin_front/core/services/list_service.dart';

class InviteFab extends StatelessWidget {
  final String listId;
  final bool isPrivate;
  final String joinCode;

  const InviteFab({
    super.key,
    required this.listId,
    required this.isPrivate,
    required this.joinCode,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Código copiado ✅')),
                                );
                              },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                ],
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
                      const SnackBar(content: Text('Invitación enviada ✅')),
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
    );
  }
}