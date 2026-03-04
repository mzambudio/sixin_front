import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sixin_front/utils/list_formatters.dart';
import '../screens.dart';
import '../../models/models.dart';
import '../../core/services/services.dart';
import '../../widgets/common/invites_badge_icon.dart';

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

  Future<void> _joinByCodeDialog(BuildContext context) async {
    final ctrl = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Introducir código'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'ABCD-EF3K-9ZQ2',
            labelText: 'Código',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (code == null) return;

    try {
      final listId = await ListService.instance.previewListByCode(
        rawCode: code,
      );

      if (!context.mounted) return;

      final placeholder = SixinList(
        id: listId,
        title: 'Lista',
        ownerName: '—',
        isPublic: false,
        items: const [],
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListDetailScreen(list: placeholder, isGuest: false),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = widget.isGuest;
    final authUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: isGuest ? null : _HomeDrawer(),
      appBar: AppBar(
        title: const Text('Sixin'),
        leading: isGuest
            ? null
            : Builder(
                builder: (context) => InvitesBadgeIcon(
                  tooltip: 'Menú',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
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
          _PublicListsTab(isGuest: isGuest),
          if (!isGuest) _MyListsTab(uid: authUser?.uid ?? ''),
        ],
      ),
      floatingActionButton: isGuest
          ? FloatingActionButton(
              onPressed: () => _showLoginRequired(context),
              tooltip: 'Inicia sesión para crear o unirte a listas',
              child: const Icon(Icons.lock),
            )
          : Stack(
              alignment: Alignment.bottomRight,
              children: [
                // FAB: introducir código (llave) - arriba
                Padding(
                  padding: const EdgeInsets.only(bottom: 72), // separa del otro
                  child: FloatingActionButton(
                    heroTag: 'fab_code',
                    tooltip: 'Introducir código',
                    child: const Icon(Icons.key),
                    onPressed: () => _joinByCodeDialog(context),
                  ),
                ),

                // FAB: crear lista (add) - abajo
                FloatingActionButton(
                  heroTag: 'fab_create',
                  tooltip: 'Crear lista',
                  child: const Icon(Icons.add),
                  onPressed: () => _createList(context),
                ),
              ],
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
/// DRAWER DE NAVEGACIÓN
/// ───────────────
class _HomeDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(leading: Icon(Icons.person), title: Text('Menú')),
            const Divider(height: 1),

            // Perfil
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Perfil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),

            // Invitaciones
            ListTile(
              leading: InvitesBadgeIcon(
                icon: Icons.mail,
                tooltip: 'Invitaciones',
                asButton: false,
              ),
              title: const Text('Invitaciones'),
              onTap: () {
                Navigator.pushNamed(context, '/inbox');
              },
            ),

            // Opciones
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Opciones'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/options',
                );
              },
            ),
          ],
        ),
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

        final rows = buildDaySections(docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final row = rows[i];

            if (row.isHeader) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  row.headerText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }

            final d = row.doc!;
            final data = d.data();

            final user = FirebaseAuth.instance.currentUser;
            final uid = user?.uid;
            final createdBy = (data['createdBy'] ?? '') as String;
            final isOwner = uid != null && createdBy == uid;

            final title = buildListTitleShort(data); // ✅ lugar + hora
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: true,
              items: const [],
            );

            final subtitleText = isOwner
                ? 'Creada por ti (${list.ownerName})'
                : 'Creada por ${list.ownerName}';

            return Card(
              child: ListTile(
                title: Text(list.title),
                subtitle: Text(subtitleText),
                trailing: const Icon(Icons.chevron_right),
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

        final rows = buildDaySections(docs);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final row = rows[i];

            if (row.isHeader) {
              return Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  row.headerText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              );
            }

            final d = row.doc!;
            final data = d.data();

            final createdBy = (data['createdBy'] ?? '') as String;
            final isOwner = createdBy == uid;

            final title = buildListTitleShort(data); // ✅ lugar + hora
            final owner = (data['ownerUsername'] ?? '—') as String;

            final list = SixinList(
              id: d.id,
              title: title,
              ownerName: owner,
              isPublic: (data['visibility'] == 'public'),
              items: const [],
            );

            final subtitleText = isOwner
                ? 'Creada por ti (${list.ownerName})'
                : 'Creada por ${list.ownerName}';

            return Card(
              child: ListTile(
                title: Text(list.title),
                subtitle: Text(subtitleText),
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

/// Helper para construir la lista de secciones (header + items) a partir de los docs, agrupando por día
class _SectionRow {
  final bool isHeader;
  final String headerText;
  final QueryDocumentSnapshot<Map<String, dynamic>>? doc;

  _SectionRow.header(this.headerText) : isHeader = true, doc = null;

  _SectionRow.item(this.doc) : isHeader = false, headerText = '';
}

List<_SectionRow> buildDaySections(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  // Ordena por startAt asc (si no viene ordenado ya por query)
  docs.sort((a, b) {
    final ta = (a.data()['startAt'] as Timestamp?)?.toDate();
    final tb = (b.data()['startAt'] as Timestamp?)?.toDate();
    if (ta == null && tb == null) return 0;
    if (ta == null) return 1;
    if (tb == null) return -1;
    return ta.compareTo(tb);
  });

  final out = <_SectionRow>[];
  String? currentKey;

  for (final d in docs) {
    final start = readStartAt(d.data())?.toLocal();
    final key = start == null ? 'sin-fecha' : dayKey(start);

    if (key != currentKey) {
      currentKey = key;
      final header = start == null ? 'Sin fecha' : dayHeaderEs(start);
      out.add(_SectionRow.header(header));
    }

    out.add(_SectionRow.item(d));
  }

  return out;
}
