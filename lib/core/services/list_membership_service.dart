import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListMembershipService {
  ListMembershipService._();
  static final instance = ListMembershipService._();

  final _db = FirebaseFirestore.instance;

  String _normalizeCode(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  String _codeHash(String normalizedCode) {
    final bytes = utf8.encode(normalizedCode);
    return sha256.convert(bytes).toString();
  }

  Future<void> joinList({required String listId, required String uid}) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(uid);
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final data = listSnap.data()!;
      final joinPolicy = (data['joinPolicy'] ?? 'open') as String;

      if (joinPolicy != 'open') {
        throw Exception('Esta lista requiere aprobación.');
      }

      final memberSnap = await tx.get(memberRef);
      if (memberSnap.exists) return;

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
    });
  }

  Future<void> requestJoin({
    required String listId,
    required String uid,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final reqRef = listRef.collection('requests').doc(uid);
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final data = listSnap.data()!;
      final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
      final memberUidsRaw = data['memberUids'];
      final memberUids = memberUidsRaw is List
          ? memberUidsRaw.map((e) => e.toString()).toList()
          : <String>[];

      if (joinPolicy != 'approval') {
        throw Exception('Esta lista es de entrada directa.');
      }

      if (memberUids.contains(uid)) {
        throw Exception('Ya perteneces a esta lista.');
      }

      final reqSnap = await tx.get(reqRef);
      if (reqSnap.exists) return;

      final userSnap = await tx.get(userRef);
      final username = (userSnap.data()?['username'] ?? uid).toString();

      tx.set(reqRef, {
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'username': username,
      });
    });
  }

  Future<void> cancelJoinRequest({
    required String listId,
    required String uid,
  }) async {
    await _db
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .doc(uid)
        .delete();
  }

  Future<String> previewListByCode({required String rawCode}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión');

    final normalized = _normalizeCode(rawCode);
    if (normalized.isEmpty) throw Exception('Código vacío');

    final hash = _codeHash(normalized);
    final codeSnap = await _db.collection('list_codes').doc(hash).get();

    if (!codeSnap.exists) throw Exception('Código inválido');

    final listId = (codeSnap.data()?['listId'] ?? '').toString();
    if (listId.isEmpty) throw Exception('Código inválido');

    final paRef = _db
        .collection('lists')
        .doc(listId)
        .collection('preview_access')
        .doc(user.uid);

    final paSnap = await paRef.get();
    if (!paSnap.exists) {
      await paRef.set({
        'codeHash': hash,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return listId;
  }

  Future<void> leaveList({
    required String listId,
    required String uid,
    required bool wasAdmin,
  }) async {
    final listRef = _db.collection('lists').doc(listId);
    final memberRef = listRef.collection('members').doc(uid);

    await _db.runTransaction((tx) async {
      final listSnap = await tx.get(listRef);
      if (!listSnap.exists) throw Exception('La lista no existe');

      final data = listSnap.data()!;
      final adminsRaw = data['admins'];
      final admins = adminsRaw is List
          ? adminsRaw.map((e) => e.toString()).toList()
          : <String>[];

      if (wasAdmin && admins.contains(uid) && admins.length <= 1) {
        throw Exception('Eres el único admin. Designa a otro antes de salir.');
      }

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      tx.delete(memberRef);

      final updates = <String, dynamic>{
        'memberUids': FieldValue.arrayRemove([uid]),
      };

      if (wasAdmin) {
        updates['admins'] = FieldValue.arrayRemove([uid]);
      }

      tx.update(listRef, updates);
    });
  }
}
