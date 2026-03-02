import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InvitesBadgeIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final bool asButton; // 👈 NUEVO

  const InvitesBadgeIcon({
    super.key,
    this.onPressed,
    this.tooltip = '',
    this.icon = Icons.person,
    this.asButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    Widget buildIcon(int count) {
      final hasInvites = count > 0;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (hasInvites)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }

    if (user == null) {
      return asButton
          ? IconButton(tooltip: tooltip, icon: Icon(icon), onPressed: onPressed)
          : Icon(icon);
    }

    final invitesStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invites')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: invitesStream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        final iconWidget = buildIcon(count);

        if (!asButton) return iconWidget;

        return IconButton(
          tooltip: tooltip,
          icon: iconWidget,
          onPressed: onPressed,
        );
      },
    );
  }
}
