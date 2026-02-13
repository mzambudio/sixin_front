import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens.dart';
import '../../models/models.dart';
import '../../core/services/services.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({super.key, required this.isGuest});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<SixinList> _publicLists = [
    SixinList(
      id: '1',
      title: 'Lista pública 1',
      ownerName: 'Usuario A',
      isPublic: true,
      items: [],
    ),
    SixinList(
      id: '2',
      title: 'Lista pública 2',
      ownerName: 'Usuario B',
      isPublic: true,
      items: [],
    ),
  ];
  final List<SixinList> _myLists = [
    SixinList(
      id: '3',
      title: 'Mi lista 1',
      ownerName: 'Yo',
      isPublic: false,
      items: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isGuest ? 1 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGuest = widget.isGuest;
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sixin'),
        actions: [
          if (!isGuest)
            IconButton(
              tooltip: 'Perfil',
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
          IconButton(
            tooltip: isGuest ? 'Iniciar sesión' : 'Cerrar sesión',
            icon: Icon(isGuest ? Icons.login : Icons.logout),
            onPressed: () async {
              try {
                if (isGuest) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                } else {
                  await AuthService.instance.signOut();
                }
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo cerrar sesión.')),
                );
              }
            },
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Listas públicas'),
            if (!isGuest) const Tab(text: 'Mis listas'),
          ],
        ),
      ),

      /// ───────────────
      /// BODY - TAB VIEWS
      /// ───────────────
      body: TabBarView(
        controller: _tabController,
        children: [
          _PublicListsTab(isGuest: isGuest),
          if (!isGuest) _MyListsTab(uid: authUser?.uid ?? ''),
        ],
      ),

      /// ───────────────
      /// ACTION BUTTON - CREAR LISTA
      /// ───────────────
      floatingActionButton: FloatingActionButton(
        onPressed: isGuest
            ? () => _showLoginRequired(context)
            : () => _createList(context),
        tooltip: isGuest ? 'Inicia sesión para crear listas' : 'Crear lista',
        child: Icon(isGuest ? Icons.lock : Icons.add),
      ),
    );
  }

  void _createList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateListScreen()),
    );
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inicia sesión para crear o unirte a listas'),
      ),
    );
  }
}

/// ───────────────
/// LISTAS PÚBLICAS
/// ───────────────
class _PublicListsTab extends StatelessWidget {
  final bool isGuest;
  const _PublicListsTab({required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ListService.instance.watchPublicLists(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No hay listas públicas'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '(sin título)') as String;
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: true,
              items: const [], // de momento
            );

            final joinPolicy = (data['joinPolicy'] ?? 'open') as String;

            return Card(
              child: ListTile(
                title: Text(list.title),
                subtitle: Text('Creada por ${list.ownerName}'),
                trailing: isGuest
                    ? const Icon(Icons.visibility)
                    : TextButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          try {
                            if (joinPolicy == 'open') {
                              await ListService.instance.joinList(
                                listId: d.id,
                                uid: user.uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Te has unido ✅'),
                                  ),
                                );
                              }
                            } else {
                              await ListService.instance.requestJoin(
                                listId: d.id,
                                uid: user.uid,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Solicitud enviada ✅'),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        child: Text(
                          joinPolicy == 'open' ? 'Unirse' : 'Solicitar',
                        ),
                      ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListDetailScreen(list: list, isGuest: isGuest),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// ───────────────
/// MIS LISTAS
/// ───────────────
class _MyListsTab extends StatelessWidget {
  final String uid;

  const _MyListsTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ListService.instance.watchMyLists(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Aún no estás en ninguna lista'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '(sin título)') as String;
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: (data['visibility'] == 'public'),
              items: const [],
            );

            return Card(
              child: ListTile(
                title: Text(list.title),
                subtitle: Text('Creada por ${list.ownerName}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ListDetailScreen(list: list, isGuest: false),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
