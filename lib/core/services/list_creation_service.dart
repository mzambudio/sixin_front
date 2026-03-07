import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class ListCreationService {
  ListCreationService._();
  static final instance = ListCreationService._();

  final _db = FirebaseFirestore.instance;

  String _generateJoinCode({int groups = 3, int groupLen = 4}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();

    String group() =>
        List.generate(groupLen, (_) => chars[rnd.nextInt(chars.length)]).join();

    return List.generate(groups, (_) => group()).join('-');
  }

  String _normalizeCode(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  String _codeHash(String normalizedCode) {
    final bytes = utf8.encode(normalizedCode);
    return sha256.convert(bytes).toString();
  }

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
}
