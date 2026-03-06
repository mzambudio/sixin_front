import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListDetailVM {
  final String listId;
  final String appTitle;

  final String joinPolicy;
  final bool isPrivate;
  final String joinCode;

  final String uid;
  final bool isAdmin;
  final bool isOnlyAdmin;
  final bool isMember;
  final bool isOnlyMember;
  final bool canSeeRequests;

  final Stream<DocumentSnapshot<Map<String, dynamic>>>? requestDocStream;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? inviteDocStream;

  ListDetailVM._({
    required this.listId,
    required this.appTitle,
    required this.joinPolicy,
    required this.isPrivate,
    required this.joinCode,
    required this.uid,
    required this.isAdmin,
    required this.isOnlyAdmin,
    required this.isMember,
    required this.isOnlyMember,
    required this.canSeeRequests,
    required this.requestDocStream,
    required this.inviteDocStream,
  });

  factory ListDetailVM.fromDoc({
    required String listId,
    required String fallbackTitle,
    required Map<String, dynamic> data,
    required bool isGuest,
  }) {
    final place = (data['place'] ?? '').toString();
    final startAtRaw = data['startAt'];
    final startAt = startAtRaw is Timestamp ? startAtRaw.toDate() : null;

    final appTitle = (place.isNotEmpty && startAt != null)
        ? '$place • ${_formatTime(startAt.toLocal())}'
        : (place.isNotEmpty ? place : fallbackTitle);

    final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
    final visibility = (data['visibility'] ?? 'public') as String;
    final joinCode = (data['joinCode'] ?? '').toString();
    final isPrivate = visibility == 'private';

    final adminsRaw = data['admins'];
    final admins = adminsRaw is List
        ? adminsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final memberUidsRaw = data['memberUids'];
    final memberUids = memberUidsRaw is List
        ? memberUidsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = uid.isNotEmpty && admins.contains(uid);
    final isOnlyAdmin = isAdmin && admins.length == 1;
    final isMember = uid.isNotEmpty && memberUids.contains(uid);
    final isOnlyMember = isMember && memberUids.length == 1;
    final canSeeRequests = !isGuest && isAdmin && joinPolicy == 'approval';

    final requestDocStream =
        (isGuest || uid.isEmpty || joinPolicy != 'approval')
        ? null
        : FirebaseFirestore.instance
              .collection('lists')
              .doc(listId)
              .collection('requests')
              .doc(uid)
              .snapshots();

    final inviteDocStream = (isGuest || uid.isEmpty)
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('invites')
              .doc(listId)
              .snapshots();

    return ListDetailVM._(
      listId: listId,
      appTitle: appTitle,
      joinPolicy: joinPolicy,
      isPrivate: isPrivate,
      joinCode: joinCode,
      uid: uid,
      isAdmin: isAdmin,
      isOnlyAdmin: isOnlyAdmin,
      isMember: isMember,
      isOnlyMember: isOnlyMember,
      canSeeRequests: canSeeRequests,
      requestDocStream: requestDocStream,
      inviteDocStream: inviteDocStream,
    );
  }

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
