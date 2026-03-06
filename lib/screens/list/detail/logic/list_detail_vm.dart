import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sixin_front/core/constants/list_form_constants.dart';

class ListDetailVM {
  final String listId;
  final String appTitle;

  final String joinPolicy;
  final bool isPrivate;
  final String joinCode;

  final String uid;
  final bool isAdmin;
  final bool isOnlyAdmin;
  final bool isMember;
  final bool isOnlyMember;
  final bool canSeeRequests;

  final Stream<DocumentSnapshot<Map<String, dynamic>>>? requestDocStream;
  final Stream<DocumentSnapshot<Map<String, dynamic>>>? inviteDocStream;

  // Nuevos campos para la UI
  final String placeLabel;
  final String? dateLabel;
  final String? timeLabel;
  final String? dateTimeLabel;
  final String? totalPriceLabel;
  final List<String> levels;
  final List<String> systems;
  final String? description;

  ListDetailVM._({
    required this.listId,
    required this.appTitle,
    required this.joinPolicy,
    required this.isPrivate,
    required this.joinCode,
    required this.uid,
    required this.isAdmin,
    required this.isOnlyAdmin,
    required this.isMember,
    required this.isOnlyMember,
    required this.canSeeRequests,
    required this.requestDocStream,
    required this.inviteDocStream,
    required this.placeLabel,
    required this.dateLabel,
    required this.timeLabel,
    required this.dateTimeLabel,
    required this.totalPriceLabel,
    required this.levels,
    required this.systems,
    required this.description,
  });

  factory ListDetailVM.fromDoc({
    required String listId,
    required String fallbackTitle,
    required Map<String, dynamic> data,
    required bool isGuest,
  }) {
    final place = (data['place'] ?? '').toString().trim();
    final customPlace = (data['customPlace'] ?? '').toString().trim();

    final startAtRaw = data['startAt'];
    final startAt = startAtRaw is Timestamp ? startAtRaw.toDate() : null;

    final appTitle = (place.isNotEmpty && startAt != null)
        ? '$place • ${_formatTime(startAt.toLocal())}'
        : (place.isNotEmpty ? place : fallbackTitle);

    final joinPolicy = (data['joinPolicy'] ?? 'open') as String;
    final visibility = (data['visibility'] ?? 'public') as String;
    final joinCode = (data['joinCode'] ?? '').toString();
    final isPrivate = visibility == 'private';

    final adminsRaw = data['admins'];
    final admins = adminsRaw is List
        ? adminsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final memberUidsRaw = data['memberUids'];
    final memberUids = memberUidsRaw is List
        ? memberUidsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = uid.isNotEmpty && admins.contains(uid);
    final isOnlyAdmin = isAdmin && admins.length == 1;
    final isMember = uid.isNotEmpty && memberUids.contains(uid);
    final isOnlyMember = isMember && memberUids.length == 1;
    final canSeeRequests = !isGuest && isAdmin && joinPolicy == 'approval';

    final requestDocStream =
        (isGuest || uid.isEmpty || joinPolicy != 'approval')
        ? null
        : FirebaseFirestore.instance
              .collection('lists')
              .doc(listId)
              .collection('requests')
              .doc(uid)
              .snapshots();

    final inviteDocStream = (isGuest || uid.isEmpty)
        ? null
        : FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('invites')
              .doc(listId)
              .snapshots();

    // ---- nuevos datos derivados ----
    final placeLabel = _buildPlaceLabel(place: place, customPlace: customPlace);

    final localStartAt = startAt?.toLocal();
    final dateLabel = localStartAt == null ? null : _formatDate(localStartAt);
    final timeLabel = localStartAt == null ? null : _formatTime(localStartAt);
    final dateTimeLabel = localStartAt == null
        ? null
        : '${_formatDate(localStartAt)} • ${_formatTime(localStartAt)}';

    final totalPriceLabel = _buildPriceLabel(data['totalPrice']);

    final levelsRaw = data['levels'];
    final levels = levelsRaw is List
        ? levelsRaw
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
        : <String>[];

    final systemsRaw = data['systems'];
    final systems = systemsRaw is List
        ? systemsRaw
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
        : <String>[];

    final descriptionRaw = (data['description'] ?? '').toString().trim();
    final description = descriptionRaw.isEmpty ? null : descriptionRaw;

    return ListDetailVM._(
      listId: listId,
      appTitle: appTitle,
      joinPolicy: joinPolicy,
      isPrivate: isPrivate,
      joinCode: joinCode,
      uid: uid,
      isAdmin: isAdmin,
      isOnlyAdmin: isOnlyAdmin,
      isMember: isMember,
      isOnlyMember: isOnlyMember,
      canSeeRequests: canSeeRequests,
      requestDocStream: requestDocStream,
      inviteDocStream: inviteDocStream,
      placeLabel: placeLabel,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      dateTimeLabel: dateTimeLabel,
      totalPriceLabel: totalPriceLabel,
      levels: levels,
      systems: systems,
      description: description,
    );
  }

  static String _buildPlaceLabel({
    required String place,
    required String customPlace,
  }) {
    if (place.isEmpty) return 'Sin lugar';

    if (place == kCustomPlaceValue) {
      return customPlace.isNotEmpty ? customPlace : 'Lugar personalizado';
    }

    return place;
  }

  static String? _buildPriceLabel(dynamic raw) {
    if (raw == null) return null;

    if (raw is num) {
      return '${raw.toStringAsFixed(2)} €';
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    return '$text €';
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _formatTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
