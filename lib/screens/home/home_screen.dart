import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({
    super.key,
    required this.isGuest,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isGuest ? 1 : 2,
      vsync: this,
    );
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
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
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
          _PublicListsTab(isGuest: isGuest),
          if (!isGuest) const _MyListsTab(),
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

class _PublicListsTab extends StatelessWidget {
  final bool isGuest;

  const _PublicListsTab({required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Lista pública ${index + 1}'),
            subtitle: const Text('Creada por un usuario'),
            trailing: isGuest
                ? const Icon(Icons.visibility)
                : const Icon(Icons.group_add),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isGuest
                        ? 'Vista solo lectura'
                        : 'Unirse a lista (no implementado)',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MyListsTab extends StatelessWidget {
  const _MyListsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text('Mi lista ${index + 1}'),
            subtitle: const Text('Participantes: 4'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detalle de lista (no implementado)'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
