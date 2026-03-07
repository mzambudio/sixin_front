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

  /// Devuelve un stream con las listas públicas ordenadas por fecha de inicio.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicLists() {
    return _db
        .collection('lists')
        .where('visibility', isEqualTo: 'public')
        .orderBy('startAt')
        .snapshots();
  }

  /// Devuelve un stream con las listas en las que participa el usuario.
  ///
  /// Se apoya en `memberUids` para evitar joins o lecturas adicionales.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyLists(String uid) {
    return _db
        .collection('lists')
        .where('memberUids', arrayContains: uid)
        .orderBy('startAt')
        .snapshots();
  }

  /// Genera un código legible para listas privadas.
  ///
  /// Se excluyen caracteres ambiguos como I, O, 1 y 0 para reducir errores
  /// al compartirlo o introducirlo manualmente.
  String _generateJoinCode({int groups = 3, int groupLen = 4}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();

    String group() =>
        List.generate(groupLen, (_) => chars[rnd.nextInt(chars.length)]).join();

    return List.generate(groups, (_) => group()).join('-');
  }

  /// Normaliza el código antes de validarlo o hashearlo.
  ///
  /// Esto permite aceptar pequeñas variaciones de entrada del usuario, como
  /// espacios accidentales o diferencias entre mayúsculas y minúsculas.
  String _normalizeCode(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Genera el hash persistido del código de acceso.
  ///
  /// La resolución se hace por hash en `list_codes` para no depender del valor
  /// en bruto como identificador de documento.
  String _codeHash(String normalizedCode) {
    final bytes = utf8.encode(normalizedCode);
    return sha256.convert(bytes).toString();
  }

  /// Crea una lista y registra al creador como primer administrador.
  ///
  /// Si la lista es privada, también genera un código de acceso y crea su
  /// entrada índice en `list_codes/{hash}`.
  ///
  /// Devuelve el código generado solo en listas privadas.
  Future<String?> createList({
    required String uid,
    required String ownerUsername,
    required String place,
    required DateTime startAt,
    required double? totalPrice,
    required List<String> levels,
    required List<String> systems,
    required String visibility,
    required String joinPolicy,
    String? description,
  }) async {
    final listsRef = _db.collection('lists').doc();
    final membersRef = listsRef.collection('members').doc(uid);

    String? joinCode;
    String? joinCodeHash;
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
      'place': place.trim(),
      'startAt': Timestamp.fromDate(startAt),
      if (totalPrice != null) 'totalPrice': totalPrice,
      'currency': 'EUR',
      'systems': [...systems]..sort(),
      'levels': [...levels]..sort(),
      'description': (description ?? '').trim(),
      'createdBy': uid,
      'admins': [uid],
      'ownerUsername': ownerUsername,
      'visibility': visibility,
      'joinPolicy': joinPolicy,
      'memberUids': [uid],
      'createdAt': now,
      'updatedAt': now,
      if (joinCodeHash != null) 'joinCodeHash': joinCodeHash,
      if (joinCode != null) 'joinCode': joinCode,
    });

    batch.set(membersRef, {
      'role': 'admin',
      'username': ownerUsername,
      'joinedAt': now,
    });

    if (codeRef != null) {
      batch.set(codeRef, {
        'listId': listsRef.id,
        'createdBy': uid,
        'createdAt': now,
      });
    }

    await batch.commit();
    return joinCode;
  }

  /// Añade directamente al usuario a la lista si la política de acceso es abierta.
  ///
  /// La operación se hace en transacción para mantener sincronizados:
  /// - `lists/{listId}.memberUids`
  /// - `lists/{listId}/members/{uid}`
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
        'username': username,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      tx.update(listRef, {
        'memberUids': FieldValue.arrayUnion([uid]),
      });
    });
  }

  /// Crea una solicitud de acceso para listas que requieren aprobación.
  ///
  /// No permite solicitar acceso si el usuario ya pertenece a la lista.
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

  /// Convierte una solicitud pendiente en membresía.
  ///
  /// Si por cualquier motivo el usuario ya era miembro, la solicitud se limpia
  /// igualmente para dejar el estado consistente.
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

  /// Rechaza una solicitud eliminando su documento.
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

  /// Permite al propio usuario retirar su solicitud pendiente.
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

  /// Elimina a un usuario de la lista.
  ///
  /// Si el usuario era administrador, también lo elimina de `admins`.
  /// Nunca permite expulsar al último administrador.
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

      if (memberSnap.exists) {
        tx.delete(memberRef);
      }

      if (reqSnap.exists) {
        tx.delete(reqRef);
      }

      final updates = <String, dynamic>{
        'memberUids': FieldValue.arrayRemove([targetUid]),
      };

      if (isTargetAdmin) {
        updates['admins'] = FieldValue.arrayRemove([targetUid]);
      }

      tx.update(listRef, updates);
    });
  }

  /// Promociona a un miembro existente a administrador.
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

  /// Revierte a un administrador al rol normal de miembro.
  ///
  /// La lista siempre debe conservar al menos un administrador.
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

  /// Permite al usuario salir de una lista.
  ///
  /// Si el usuario es el último administrador, la salida se bloquea hasta que
  /// designe a otro admin.
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

  /// URL base del backend usada desde el emulador Android.
  ///
  /// `10.0.2.2` apunta al host local de la máquina desde el emulador.
  static const String _baseUrl = 'http://10.0.2.2:3000';

  /// Solicita al backend la eliminación completa de una lista.
  ///
  /// Esta operación se delega al servidor porque puede implicar borrar varias
  /// colecciones o aplicar comprobaciones que no conviene dejar solo en cliente.
  Future<void> deleteGroupViaBackend({required String listId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión activa');

    final token = await user.getIdToken();
    final uri = Uri.parse('$_baseUrl/api/lists/$listId');

    final resp = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      body = null;
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = (body?['error'] ?? 'HTTP ${resp.statusCode}').toString();
      throw Exception(msg);
    }
  }

  /// Crea una invitación pendiente resolviendo al destinatario por username.
  ///
  /// La invitación se almacena en el buzón del receptor:
  /// `users/{toUid}/invites/{listId}`.
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

  /// Valida un código de acceso y devuelve el `listId` asociado.
  ///
  /// Si el código es correcto, crea `preview_access/{uid}` para que el usuario
  /// pueda ver una lista privada sin haber entrado todavía como miembro.
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

  /// Acepta una invitación pendiente y convierte al usuario en miembro.
  ///
  /// Si el usuario ya era miembro, la invitación se elimina igualmente para
  /// evitar estados residuales en el buzón.
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

  /// Rechaza una invitación eliminándola del buzón del usuario.
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