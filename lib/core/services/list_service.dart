import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ListService {
  ListService._();
  static final instance = ListService._();

  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicLists() {
    return _db
        .collection('lists')
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyLists(String uid) {
    return _db
        .collection('lists')
        .where('memberUids', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ─────────────────────────────────────────────
  // CREATE LIST (+ optional private join code)
  // ─────────────────────────────────────────────
  String _generateJoinCode({int groups = 3, int groupLen = 4}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sin I/O/1/0
    final rnd = Random.secure();

    String group() =>
        List.generate(groupLen, (_) => chars[rnd.nextInt(chars.length)]).join();
    return List.generate(groups, (_) => group()).join('-'); // ABCD-EF3K-9ZQ2
  }

  String _normalizeCode(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  String _codeHash(String normalizedCode) {
    final bytes = utf8.encode(normalizedCode);
    return sha256.convert(bytes).toString();
  }

  /// Crea una lista.
  /// Devuelve el código (solo si private), si no devuelve null.
  Future<String?> createList({
    required String uid,
    required String ownerUsername, // guárdalo para mostrarlo en Home sin joins
    required String title,
    required String visibility, // "public" | "private"
    required String joinPolicy, // "open" | "approval"
    String? description,
  }) async {
    final listsRef = _db.collection('lists').doc();
    final membersRef = listsRef.collection('members').doc(uid);

    String? joinCode;
    String? joinCodeHash;

    // Si es privada, generamos código y hash y creamos doc índice list_codes/{hash}
    DocumentReference<Map<String, dynamic>>? codeRef;
    if (visibility == 'private') {
      joinCode = _generateJoinCode();
      final normalized = _normalizeCode(joinCode);
      joinCodeHash = _codeHash(normalized);
      codeRef = _db.collection('list_codes').doc(joinCodeHash);
    }

    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();

    batch.set(listsRef, {
      'title': title.trim(),
      'description': (description ?? '').trim(),
      'createdBy': uid,
      'admins': [uid],
      'ownerUsername': ownerUsername,
      'visibility': visibility, // public/private
      'joinPolicy': joinPolicy, // open/approval
      'memberUids': [uid], // para "Mis listas" fácil
      'createdAt': now,
      'updatedAt': now,
      if (joinCodeHash != null) 'joinCodeHash': joinCodeHash,
    });

    batch.set(membersRef, {
      'role': 'admin',
      'username': ownerUsername, // ✅
      'joinedAt': now,
    });

    if (codeRef != null) {
      batch.set(codeRef, {'listId': listsRef.id, 'createdAt': now});
    }

    await batch.commit();
    return joinCode;
  }

  // ─────────────────────────────────────────────
  // JOIN / REQUEST JOIN
  // ─────────────────────────────────────────────
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
      final userData = userSnap.data();
      final username = (userData?['username'] ?? uid).toString();

      tx.set(memberRef, {
        'role': 'member',
        'username': username, // ✅
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

      // Si ya es miembro, no puede pedir
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

  // ─────────────────────────────────────────────
  // REJECT / APPROVE REQUEST
  // ─────────────────────────────────────────────
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

      // Evitar duplicados
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
    final reqRef = _db
        .collection('lists')
        .doc(listId)
        .collection('requests')
        .doc(requesterUid);

    await reqRef.delete();
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

      final memberSnap = await tx.get(memberRef);
      final reqSnap = await tx.get(reqRef);

      if (memberSnap.exists) {
        tx.delete(memberRef);
      }

      if (reqSnap.exists) {
        tx.delete(reqRef);
      }

      tx.update(listRef, {
        'memberUids': FieldValue.arrayRemove([targetUid]),
      });
    });
  }

  Future<void> deleteListViaBackend({required String listId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay sesión activa');
    }

    final token = await user.getIdToken();

    // Android Emulator: usa 10.0.2.2 en vez de localhost
    // Dispositivo físico: usa la IP local del PC
    final uri = Uri.parse('http://10.0.2.2:3000/api/lists/$listId');

    final resp = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    Map<String, dynamic>? data;
    try {
      data = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      data = null;
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = (data?['error'] ?? 'Error HTTP ${resp.statusCode}')
          .toString();
      throw Exception(msg);
    }
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

      // WRITES después
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

      if (!admins.contains(targetUid)) {
        return;
      }

      // No dejes la lista sin admins
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

      // Si era admin y es el último admin, no puede salir
      if (wasAdmin && admins.where((a) => a == uid).isNotEmpty) {
        if (admins.length <= 1) {
          throw Exception(
            'Eres el único admin. Designa a otro antes de salir.',
          );
        }
      }

      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) {
        return;
      }

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
