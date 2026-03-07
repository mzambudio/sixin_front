import 'package:cloud_firestore/cloud_firestore.dart';

class ListAdminService {
  ListAdminService._();
  static final instance = ListAdminService._();

  final _db = FirebaseFirestore.instance;

  Future<void> approveRequest({
    required String listId,
    required String requesterUid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final reqRef = listRef.collection('requests').doc(requesterUid);
    final memberRef = listRef.collection('members').doc(requesterUid);
    final userRef = _db.collection('users').doc(requesterUid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw Exception('La solicitud ya no existe');

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        final userSnap = await tx.get(userRef);
        final username = (userSnap.data()?['username'] ?? requesterUid)
            .toString();

        tx.set(memberRef, {
          'role': 'member',
          'username': username,
          'joinedAt': FieldValue.serverTimestamp(),
        });

        tx.update(listRef, {
          'memberUids': FieldValue.arrayUnion([requesterUid]),
        });
      }

      tx.delete(reqRef);
    });
  }

  Future<void> rejectRequest({
    required String listId,
    required String requesterUid,
  }) async {
    await _db
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .doc(requesterUid)
        .delete();
  }

  Future<void> removeMember({
    required String listId,
    required String targetUid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(targetUid);
    final reqRef = listRef.collection('requests').doc(targetUid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final data = listSnap.data()!;
      final adminsRaw = data['admins'];
      final admins = adminsRaw is List
          ? adminsRaw.map((e) => e.toString()).toList()
          : <String>[];

      final isTargetAdmin = admins.contains(targetUid);
      if (isTargetAdmin && admins.length <= 1) {
        throw Exception('No puedes expulsar al último administrador.');
      }

      final memberSnap = await tx.get(memberRef);
      final reqSnap = await tx.get(reqRef);

      if (memberSnap.exists) tx.delete(memberRef);
      if (reqSnap.exists) tx.delete(reqRef);

      final updates = <String, dynamic>{
        'memberUids': FieldValue.arrayRemove([targetUid]),
      };

      if (isTargetAdmin) {
        updates['admins'] = FieldValue.arrayRemove([targetUid]);
      }

      tx.update(listRef, updates);
    });
  }

  Future<void> makeAdmin({
    required String listId,
    required String targetUid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(targetUid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) throw Exception('Ese usuario no es miembro');

      tx.update(memberRef, {'role': 'admin'});
      tx.update(listRef, {
        'admins': FieldValue.arrayUnion([targetUid]),
      });
    });
  }

  Future<void> demoteAdmin({
    required String listId,
    required String targetUid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(targetUid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final data = listSnap.data()!;
      final adminsRaw = data['admins'];
      final admins = adminsRaw is List
          ? adminsRaw.map((e) => e.toString()).toList()
          : <String>[];

      if (!admins.contains(targetUid)) return;

      if (admins.length <= 1) {
        throw Exception('Debe quedar al menos un administrador.');
      }

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) throw Exception('Ese usuario no es miembro');

      tx.update(memberRef, {'role': 'member'});
      tx.update(listRef, {
        'admins': FieldValue.arrayRemove([targetUid]),
      });
    });
  }
}
