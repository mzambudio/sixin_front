import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SettingsController {
  SettingsController._();
  static final instance = SettingsController._();

  final ValueNotifier<String> positionsLang = ValueNotifier<String>(
    'es',
  );

  StreamSubscription? _sub;

  Future<void> start() async {
    stop();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('ui');

    _sub = docRef.snapshots().listen((snap) {
      final data = snap.data() ?? {};
      final lang = (data['positionsLang'] ?? 'es').toString();
      if (lang == 'en' || lang == 'es') {
        positionsLang.value = lang;
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    positionsLang.value = 'es';
  }

  Future<void> setPositionsLang(String lang) async {
    if (lang != 'es' && lang != 'en') return;

    positionsLang.value = lang;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('settings')
        .doc('ui')
        .set({'positionsLang': lang}, SetOptions(merge: true));
  }
}
