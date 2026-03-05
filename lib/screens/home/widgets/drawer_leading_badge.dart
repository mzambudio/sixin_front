import 'package:flutter/material.dart';
import '../../../widgets/common/invites_badge_icon.dart';

class DrawerLeadingBadge extends StatelessWidget {
  const DrawerLeadingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => InvitesBadgeIcon(
        tooltip: 'Menú',
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }
}