import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sixin_front/screens/list/detail/logic/list_detail_vm.dart';
import '../../../models/models.dart';
import 'widgets/widgets.dart';

class ListDetailScreen extends StatelessWidget {
  final SixinList list;
  final bool isGuest;

  const ListDetailScreen({
    super.key,
    required this.list,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    final listId = list.id;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('lists')
          .doc(listId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _stateScaffold(
            title: list.title,
            body: Center(child: Text('Error: ${snap.error}')),
          );
        }

        if (!snap.hasData) {
          return _stateScaffold(
            title: list.title,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data!;
        final data = doc.data();

        if (!doc.exists || data == null) {
          return _stateScaffold(
            title: list.title,
            body: const Center(child: Text('La lista no existe')),
          );
        }

        // --- VM: todo lo derivado del doc ---
        final vm = ListDetailVM.fromDoc(
          listId: listId,
          fallbackTitle: list.title,
          data: data,
          isGuest: isGuest,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(vm.appTitle),
            actions: [
              if (vm.canSeeRequests)
                RequestsBadgeButton(
                  listId: listId,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => RequestsSheet(listId: listId),
                    );
                  },
                ),
              if (!isGuest && vm.isAdmin) SettingsMenu(listId: listId),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Miembros', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              MembersList(
                listId: listId,
                isAdmin: vm.isAdmin,
                currentUid: vm.uid,
              ),
            ],
          ),
          floatingActionButton: (isGuest || !vm.isAdmin)
              ? null
              : InviteFab(
                  listId: listId,
                  isPrivate: vm.isPrivate,
                  joinCode: vm.joinCode,
                ),
          bottomNavigationBar: isGuest
              ? null
              : JoinBar(
                  listId: listId,
                  isGuest: isGuest,
                  uid: vm.uid,
                  isMember: vm.isMember,
                  isOnlyMember: vm.isOnlyMember,
                  isOnlyAdmin: vm.isOnlyAdmin,
                  wasAdmin: vm.isAdmin,
                  joinPolicy: vm.joinPolicy,
                  inviteDocStream: vm.inviteDocStream,
                  requestDocStream: vm.requestDocStream,
                ),
        );
      },
    );
  }

  Widget _stateScaffold({required String title, required Widget body}) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}
