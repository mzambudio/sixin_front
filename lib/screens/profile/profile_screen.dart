import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'package:sixin_front/core/services/profile_service.dart';
import 'package:sixin_front/core/settings/settings_controller.dart';
import 'package:sixin_front/core/constants/volley_positions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: Text('No hay sesión activa')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            tooltip: 'Editar perfil',
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ProfileService.instance.watchUserDoc(authUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error cargando perfil'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Cargando...'));
          }

          final doc = snapshot.data!;
          final data = doc.data();
          if (!doc.exists || data == null) {
            return const Center(
              child: Text('No existe el documento del usuario'),
            );
          }

          final username = (data['username'] ?? '') as String;
          final photoUrl = (data['photoUrl'] ?? '') as String;

          final positionsRaw = data['positions'];
          final positions = positionsRaw is List
              ? positionsRaw.map((e) => e.toString()).toList()
              : <String>[];

          final createdAtRaw = data['createdAt'];
          final createdAt = createdAtRaw is Timestamp
              ? createdAtRaw.toDate()
              : null;
          final date = createdAt?.toLocal();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: ClipOval(
                    child: photoUrl.trim().isEmpty
                        ? Center(
                            child: Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            ),
                          )
                        : Image.network(
                            photoUrl,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  username.isNotEmpty
                                      ? username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 32),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  username.isNotEmpty ? username : '(sin username)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<String>(
                valueListenable: SettingsController.instance.positionsLang,
                builder: (context, langStr, _) {
                  final lang = (langStr == 'en')
                      ? PositionsLang.en
                      : PositionsLang.es;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.security),
                      title: Text(
                        lang == PositionsLang.es ? 'Posiciones' : 'Positions',
                      ),
                      subtitle: positions.isEmpty
                          ? const Text('—')
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: positions.map((id) {
                                final p = volleyPositions
                                    .where((x) => x.id == id)
                                    .cast<VolleyPosition?>()
                                    .firstWhere(
                                      (x) => x != null,
                                      orElse: () => null,
                                    );

                                return Tooltip(
                                  message: p == null
                                      ? id.toUpperCase()
                                      : p.name(lang),
                                  waitDuration: const Duration(
                                    milliseconds: 350,
                                  ),
                                  showDuration: const Duration(seconds: 2),
                                  child: Chip(
                                    label: Text(
                                      p == null
                                          ? id.toUpperCase()
                                          : p.abbr(lang),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  );
                },
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Cuenta creada'),
                  subtitle: Text(
                    date == null
                        ? '—'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} - '
                              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
