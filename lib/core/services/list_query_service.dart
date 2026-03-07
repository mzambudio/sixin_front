import 'package:cloud_firestore/cloud_firestore.dart';

class ListQueryService {
  ListQueryService._();
  static final instance = ListQueryService._();

  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicLists() {
    return _db
        .collection('lists')
        .where('visibility', isEqualTo: 'public')
        .orderBy('startAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyLists(String uid) {
    return _db
        .collection('lists')
        .where('memberUids', arrayContains: uid)
        .orderBy('startAt')
        .snapshots();
  }
}