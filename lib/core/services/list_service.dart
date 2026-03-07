import 'package:cloud_firestore/cloud_firestore.dart';
import 'list_admin_service.dart';
import 'list_backend_service.dart';
import 'list_creation_service.dart';
import 'list_invitation_service.dart';
import 'list_membership_service.dart';
import 'list_query_service.dart';

class ListService {
  ListService._();
  static final instance = ListService._();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPublicLists() {
    return ListQueryService.instance.watchPublicLists();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyLists(String uid) {
    return ListQueryService.instance.watchMyLists(uid);
  }

  Future<String?> createList({
    required String uid,
    required String ownerUsername,
    required String place,
    required DateTime startAt,
    required double? totalPrice,
    required List<String> levels,
    required List<String> systems,
    required String visibility,
    required String joinPolicy,
    String? description,
  }) {
    return ListCreationService.instance.createList(
      uid: uid,
      ownerUsername: ownerUsername,
      place: place,
      startAt: startAt,
      totalPrice: totalPrice,
      levels: levels,
      systems: systems,
      visibility: visibility,
      joinPolicy: joinPolicy,
      description: description,
    );
  }

  Future<void> joinList({required String listId, required String uid}) {
    return ListMembershipService.instance.joinList(listId: listId, uid: uid);
  }

  Future<void> requestJoin({required String listId, required String uid}) {
    return ListMembershipService.instance.requestJoin(listId: listId, uid: uid);
  }

  Future<void> cancelJoinRequest({
    required String listId,
    required String uid,
  }) {
    return ListMembershipService.instance.cancelJoinRequest(
      listId: listId,
      uid: uid,
    );
  }

  Future<String> previewListByCode({required String rawCode}) {
    return ListMembershipService.instance.previewListByCode(rawCode: rawCode);
  }

  Future<void> leaveList({
    required String listId,
    required String uid,
    required bool wasAdmin,
  }) {
    return ListMembershipService.instance.leaveList(
      listId: listId,
      uid: uid,
      wasAdmin: wasAdmin,
    );
  }

  Future<void> approveRequest({
    required String listId,
    required String requesterUid,
  }) {
    return ListAdminService.instance.approveRequest(
      listId: listId,
      requesterUid: requesterUid,
    );
  }

  Future<void> rejectRequest({
    required String listId,
    required String requesterUid,
  }) {
    return ListAdminService.instance.rejectRequest(
      listId: listId,
      requesterUid: requesterUid,
    );
  }

  Future<void> removeMember({
    required String listId,
    required String targetUid,
  }) {
    return ListAdminService.instance.removeMember(
      listId: listId,
      targetUid: targetUid,
    );
  }

  Future<void> makeAdmin({required String listId, required String targetUid}) {
    return ListAdminService.instance.makeAdmin(
      listId: listId,
      targetUid: targetUid,
    );
  }

  Future<void> demoteAdmin({
    required String listId,
    required String targetUid,
  }) {
    return ListAdminService.instance.demoteAdmin(
      listId: listId,
      targetUid: targetUid,
    );
  }

  Future<void> inviteByUsername({
    required String listId,
    required String usernameInput,
  }) {
    return ListInvitationService.instance.inviteByUsername(
      listId: listId,
      usernameInput: usernameInput,
    );
  }

  Future<void> acceptInvite({required String listId, required String uid}) {
    return ListInvitationService.instance.acceptInvite(
      listId: listId,
      uid: uid,
    );
  }

  Future<void> rejectInvite({required String listId, required String uid}) {
    return ListInvitationService.instance.rejectInvite(
      listId: listId,
      uid: uid,
    );
  }

  Future<void> deleteGroupViaBackend({required String listId}) {
    return ListBackendService.instance.deleteGroupViaBackend(listId: listId);
  }
}
