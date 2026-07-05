import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/models/message_model.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});

class GroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  GroupRepository(this._firestore, this._storage);

  Future<void> createGroup({
    required String name,
    required File? image,
    required List<String> memberIds,
    required String currentUserId,
  }) async {
    final groupId = const Uuid().v4();
    String groupPicUrl = '';

    if (image != null) {
      final ref = _storage.ref().child('groups/$groupId/profilePic');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      groupPicUrl = await snapshot.ref.getDownloadURL();
    }

    final group = GroupModel(
      id: groupId,
      name: name,
      groupPicUrl: groupPicUrl,
      ownerId: currentUserId,
      adminIds: [currentUserId],
      memberIds: [...memberIds, currentUserId], // Ensure creator is in the group
      createdAt: DateTime.now(),
    );

    await _firestore.collection('groups').doc(groupId).set(group.toJson());
  }

  Stream<List<GroupModel>> getUserGroups(String currentUserId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              // Firestore returns Timestamp objects, not strings — convert them manually
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
              }
              if (data['lastMessageTime'] is Timestamp) {
                data['lastMessageTime'] = (data['lastMessageTime'] as Timestamp).toDate().toIso8601String();
              }
              return GroupModel.fromJson(data);
            }).toList());
  }

  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromJson(doc.data())).toList());
  }

  Future<void> sendGroupMessage({
    required String groupId,
    required String currentUserId,
    required String text,
  }) async {
    final messageId = const Uuid().v4();
    
    final message = MessageModel(
      id: messageId,
      senderId: currentUserId,
      receiverId: groupId, // Using groupId as receiver
      text: text,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    final groupDoc = _firestore.collection('groups').doc(groupId);
    final msgDoc = groupDoc.collection('messages').doc(messageId);

    batch.set(msgDoc, message.toJson());
    batch.set(groupDoc, {
      'lastMessage': text,
      'lastMessageSenderId': currentUserId, // Added this field
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> removeMember(String groupId, String memberId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
      'adminIds': FieldValue.arrayRemove([memberId]), // Remove from admins if they were one
    });
  }

  Future<void> makeAdmin(String groupId, String memberId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'adminIds': FieldValue.arrayUnion([memberId]),
    });
  }
}
