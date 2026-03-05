import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestsBadgeButton extends StatelessWidget {
  final String listId;
  final VoidCallback onTap;

  const RequestsBadgeButton({
    super.key,
    required this.listId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countStream = FirebaseFirestore.instance
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: countStream,
      builder: (context, snap) {
        final count = snap.data?.size ?? 0;

        return IconButton(
          tooltip: 'Solicitudes',
          onPressed: onTap,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.inbox),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
