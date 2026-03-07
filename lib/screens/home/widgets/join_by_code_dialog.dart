import 'package:flutter/material.dart';
import 'package:sixin_front/core/services/services.dart';
import 'package:sixin_front/screens/list/detail/list_detail_screen.dart';
import 'package:sixin_front/models/models.dart';

Future<void> showJoinByCodeFlow(BuildContext context) async {
  final ctrl = TextEditingController();

  final code = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Introducir código'),
      content: TextField(
        controller: ctrl,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          hintText: 'ABCD-EF3K-9ZQ2',
          labelText: 'Código',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );

  if (code == null) return;

  try {
    final listId = await ListMembershipService.instance.previewListByCode(rawCode: code);

    if (!context.mounted) return;

    final placeholder = SixinList(
      id: listId,
      title: 'Lista',
      ownerName: '—',
      isPublic: false,
      items: const [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailScreen(list: placeholder, isGuest: false),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}
