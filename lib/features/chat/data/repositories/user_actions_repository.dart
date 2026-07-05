import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final userActionsRepositoryProvider = Provider<UserActionsRepository>((ref) {
  return UserActionsRepository(FirebaseFirestore.instance);
});

/// Handles cross-cutting user actions: Block, Report, Archive, Pin
class UserActionsRepository {
  final FirebaseFirestore _firestore;

  UserActionsRepository(this._firestore);

  // ──────────────── BLOCK ────────────────

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayRemove([targetUserId]),
    });
  }

  Stream<bool> isUserBlocked(String currentUserId, String targetUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      if (!doc.exists) return false;
      final blocked = List<String>.from(doc.data()?['blockedUsers'] ?? []);
      return blocked.contains(targetUserId);
    });
  }

  // ──────────────── REPORT ────────────────

  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ──────────────── ARCHIVE ────────────────

  Future<void> archiveChat(String currentUserId, String chatId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'archivedChats': FieldValue.arrayUnion([chatId]),
    });
  }

  Future<void> unarchiveChat(String currentUserId, String chatId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'archivedChats': FieldValue.arrayRemove([chatId]),
    });
  }

  // ──────────────── PIN ────────────────

  Future<void> pinChat(String currentUserId, String chatId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'pinnedChats': FieldValue.arrayUnion([chatId]),
    });
  }

  Future<void> unpinChat(String currentUserId, String chatId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'pinnedChats': FieldValue.arrayRemove([chatId]),
    });
  }

  Stream<List<String>> getPinnedChats(String currentUserId) {
    return _firestore.collection('users').doc(currentUserId).snapshots().map((doc) {
      return List<String>.from(doc.data()?['pinnedChats'] ?? []);
    });
  }
}
