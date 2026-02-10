import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  /// Actualiza posiciones (array)
  Future<void> updatePositions({
    required String uid,
    required List<String> positions,
  }) async {
    final cleaned =
        positions
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    await _db.collection('users').doc(uid).update({
      'positions': cleaned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Sube foto a Storage y guarda photoUrl en users/{uid}
  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile file,
  }) async {
    // siempre el mismo archivo
    final ref = _storage.ref().child('profile_photos/$uid/avatar.jpg');

    // sube (sobrescribe)
    await ref.putFile(
      File(file.path),
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // URL base
    final url = await ref.getDownloadURL();

    // cache-buster para que se refresque en el móvil aunque seaTF cachee
    final bustedUrl = '$url&v=${DateTime.now().millisecondsSinceEpoch}';

    await _db.collection('users').doc(uid).update({
      'photoUrl': bustedUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return bustedUrl;
  }

  /// Cambia el username asegurando unicidad con usernames/{usernameLower}
  /// - Lee el username actual para borrar el doc antiguo en usernames
  /// - Comprueba si el nuevo ya existe y pertenece a otro uid
  /// - Actualiza users/{uid} y usernames/{newLower}, y borra usernames/{oldLower}
  Future<void> updateUsername({
    required String uid,
    required String newUsername,
  }) async {
    final trimmed = newUsername.trim();

    final reg = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!reg.hasMatch(trimmed)) {
      throw Exception(
        'Username inválido. Usa 3-20 caracteres: letras, números o _',
      );
    }

    final newLower = trimmed.toLowerCase();

    final usersRef = _db.collection('users').doc(uid);
    final newUsernameRef = _db.collection('usernames').doc(newLower);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(usersRef);
      if (!userSnap.exists) throw Exception('No existe users/$uid');

      final userData = userSnap.data() as Map<String, dynamic>;
      final oldLower = (userData['usernameLower'] as String?)?.trim() ?? '';

      // Si no cambia, no hacemos nada
      if (oldLower == newLower) return;

      // ¿Existe el nuevo username?
      final takenSnap = await tx.get(newUsernameRef);
      if (takenSnap.exists) {
        final takenData = takenSnap.data() as Map<String, dynamic>;
        final takenUid = (takenData['uid'] as String?) ?? '';
        if (takenUid != uid) {
          throw Exception('Ese username ya está en uso.');
        }
        // Si es tuyo, ya está reservado: NO hacemos set (evitamos UPDATE)
      } else {
        // Crear reserva SOLO si no existe (CREATE)
        tx.set(newUsernameRef, {
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Actualizar users/{uid}
      tx.update(usersRef, {
        'username': trimmed,
        'usernameLower': newLower,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Borrar el username viejo (DELETE permitido si es tuyo)
      if (oldLower.isNotEmpty) {
        tx.delete(_db.collection('usernames').doc(oldLower));
      }
    });
  }
}
