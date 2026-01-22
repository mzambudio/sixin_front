import 'package:flutter/material.dart';
import '../../widgets/common/theme_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.isGuest = false,
  });

  final bool isGuest;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  /// ───────────────
  /// TABS
  /// ───────────────
  final List<Widget> _tabs = const [
    _HomeTab(),
    _MatchTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SixIn'),
        actions: [
          IconButton(
            tooltip: 'Editar tema',
            icon: const Icon(Icons.palette),
            onPressed: () => ThemeEditor.show(context),
          ),
        ],
      ),

      /// ───────────────
      /// BODY
      /// ───────────────
      body: Column(
        children: [
          /// Guest banner
          if (widget.isGuest)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: isDark ? Colors.orange.shade900 : Colors.orange.shade100,
              child: const Text(
                'Estás navegando como invitado',
                textAlign: TextAlign.center,
              ),
            ),

          /// Active tab
          Expanded(
            child: _tabs[_currentIndex],
          ),
        ],
      ),

      /// ───────────────
      /// BOTTOM NAV
      /// ───────────────
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// HOME TAB
/// ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// MATCH TAB
/// ─────────────────────────────────────────────
class _MatchTab extends StatelessWidget {
  const _MatchTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Match',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// PROFILE TAB
/// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Perfil',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
