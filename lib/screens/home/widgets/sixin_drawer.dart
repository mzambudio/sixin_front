import 'package:flutter/material.dart';
import 'package:sixin_front/widgets/common/invites_badge_icon.dart';

class SixinDrawer extends StatelessWidget {
  const SixinDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(leading: Icon(Icons.person), title: Text('Menú')),
            const Divider(height: 1),

            // Perfil
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            // Buzón
            ListTile(
              leading: InvitesBadgeIcon(
                icon: Icons.mail,
                tooltip: 'Buzón',
                asButton: false,
              ),
              title: const Text('Buzón'),
              onTap: () {
                Navigator.pushNamed(context, '/inbox');
              },
            ),

            // Opciones
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Opciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/options');
              },
            ),
          ],
        ),
      ),
    );
  }
}
