import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _uiRef(String uid) =>
      _db.collection('users').doc(uid).collection('settings').doc('ui');

  Stream<Map<String, dynamic>> watchUi() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return _uiRef(user.uid).snapshots().map((s) => s.data() ?? {});
  }

  Future<void> setPositionsLang(String lang) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay sesión');
    await _uiRef(user.uid).set({'positionsLang': lang}, SetOptions(merge: true));
  }
}