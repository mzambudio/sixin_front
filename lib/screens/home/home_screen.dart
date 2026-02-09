import 'package:flutter/material.dart';
import '../screens.dart';
import '../../models/models.dart';
import '../../core/services/auth_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('SixIn'),
        actions: [
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
      /// BODY
      /// ───────────────
      body: TabBarView(
        controller: _tabController,
        children: [
          _PublicListsTab(lists: _publicLists, isGuest: isGuest),
          if (!isGuest) _MyListsTab(lists: _myLists),
        ],
      ),

      /// ───────────────
      /// ACTION BUTTON
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Crear lista (no implementado aún)')),
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
  final List<SixinList> lists;

  const _PublicListsTab({required this.isGuest, required this.lists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          child: ListTile(
            title: Text(list.title),
            subtitle: Text('Creada por ${list.ownerName}'),
            trailing: isGuest
                ? const Icon(Icons.visibility)
                : const Icon(Icons.group_add),
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
  }
}

/// ───────────────
/// MIS LISTAS
/// ───────────────
class _MyListsTab extends StatelessWidget {
  final List<SixinList> lists;

  const _MyListsTab({required this.lists});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        return Card(
          child: ListTile(
            title: Text(list.title),
            subtitle: Text('Participantes: ${list.items.length}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ListDetailScreen(list: list, isGuest: false),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
