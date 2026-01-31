import 'package:flutter/material.dart';

class ListDetailScreen extends StatelessWidget {
  final String title;
  final bool isGuest;

  const ListDetailScreen({
    super.key,
    required this.title,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(
          isGuest
              ? 'Viendo como invitado'
              : 'Viendo como usuario registrado',
        ),
      ),
    );
  }
}