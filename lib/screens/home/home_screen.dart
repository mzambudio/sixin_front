import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/screens/home/widgets/widgets.dart';
import '../screens.dart';
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
    final isGuest = widget.isGuest;
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: isGuest ? null : SixinDrawer(),
      appBar: AppBar(
        title: const Text('Sixin'),
        leading: isGuest ? null : const DrawerLeadingBadge(),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          PublicListsTab(isGuest: isGuest),
          if (!isGuest) MyListsTab(uid: authUser?.uid ?? ''),
        ],
      ),
      floatingActionButton: HomeFab(
        isGuest: isGuest,
        onLoginRequired: () => _showLoginRequired(context),
        onJoinByCode: () => showJoinByCodeFlow(context),
        onCreateList: () => _createList(context),
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
