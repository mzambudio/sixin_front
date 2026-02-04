import 'sixin_list_item.dart';

class SixinList {
  final String id;
  final String title;
  final String ownerName;
  final bool isPublic;
  final List<SixinListItem> items;

  SixinList({
    required this.id,
    required this.title,
    required this.ownerName,
    required this.isPublic,
    required this.items,
  });
}
