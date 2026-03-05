import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showAccessCodeDialog(BuildContext context, String code) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Código de acceso'),
      content: Row(
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Código copiado ✅')));
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
