import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ListBackendService {
  ListBackendService._();
  static final instance = ListBackendService._();

  static const String _baseUrl = 'http://10.0.2.2:3000';

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
}
