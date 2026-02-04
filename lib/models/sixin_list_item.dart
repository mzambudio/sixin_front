class SixinListItem {
  final String id;
  final String title;
  final bool completed;

  const SixinListItem({
    required this.id,
    required this.title,
    this.completed = false,
  });

  SixinListItem copyWith({bool? completed}) {
    return SixinListItem(
      id: id,
      title: title,
      completed: completed ?? this.completed,
    );
  }
}
