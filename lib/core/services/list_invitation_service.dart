import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListInvitationService {
  ListInvitationService._();
  static final instance = ListInvitationService._();

  final _db = FirebaseFirestore.instance;

  Future<void> inviteByUsername({
    required String listId,
    required String usernameInput,
  }) async {
    final from = FirebaseAuth.instance.currentUser;
    if (from == null) throw Exception('No hay sesión');

    final trimmed = usernameInput.trim();
    if (trimmed.isEmpty) throw Exception('Escribe un username');

    final unameLower = trimmed.toLowerCase();
    final unameSnap = await _db.collection('usernames').doc(unameLower).get();

    if (!unameSnap.exists) throw Exception('Ese username no existe');

    final toUid = (unameSnap.data()?['uid'] ?? '').toString();
    if (toUid.isEmpty) throw Exception('Username inválido');
    if (toUid == from.uid) throw Exception('No puedes invitarte a ti mismo');

    final listRef = _db.collection('lists').doc(listId);
    final listSnap = await listRef.get();
    if (!listSnap.exists) throw Exception('La lista no existe');

    final data = listSnap.data()!;
    final adminsRaw = data['admins'];
    final admins = adminsRaw is List
        ? adminsRaw.map((e) => e.toString()).toList()
        : <String>[];

    if (!admins.contains(from.uid)) {
      throw Exception('Solo un admin puede invitar');
    }

    final memberUidsRaw = data['memberUids'];
    final memberUids = memberUidsRaw is List
        ? memberUidsRaw.map((e) => e.toString()).toList()
        : <String>[];

    if (memberUids.contains(toUid)) {
      throw Exception('Ese usuario ya está en la lista');
    }

    final fromUserSnap = await _db.collection('users').doc(from.uid).get();
    final fromUsername = (fromUserSnap.data()?['username'] ?? '').toString();

    final place = (data['place'] ?? '(sin lugar)').toString();
    final startAtRaw = data['startAt'];
    final Timestamp? startAt = startAtRaw is Timestamp ? startAtRaw : null;

    final inviteRef = _db
        .collection('users')
        .doc(toUid)
        .collection('invites')
        .doc(listId);

    await inviteRef.set({
      'listId': listId,
      'listPlace': place,
      if (startAt != null) 'startAt': startAt,
      'fromUid': from.uid,
      'fromUsername': fromUsername,
      'toUsername': trimmed,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> acceptInvite({
    required String listId,
    required String uid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(uid);
    final inviteRef = _db
        .collection('users')
        .doc(uid)
        .collection('invites')
        .doc(listId);
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) {
        throw Exception('La invitación ya no existe');
      }

      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        final userSnap = await tx.get(userRef);
        final username = (userSnap.data()?['username'] ?? uid).toString();

        tx.set(memberRef, {
          'role': 'member',
          'username': username,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        tx.update(listRef, {
          'memberUids': FieldValue.arrayUnion([uid]),
        });
      }

      tx.delete(inviteRef);
    });
  }

  Future<void> rejectInvite({
    required String listId,
    required String uid,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('invites')
        .doc(listId)
        .delete();
  }
}
