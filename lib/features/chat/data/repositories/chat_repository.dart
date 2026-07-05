import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/message_model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatRepository(this._firestore, this._storage);

  // Generates a unique chat ID based on two user IDs sorted alphabetically
  String getChatId(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  // Stream of messages ordered by time
  Stream<List<MessageModel>> getMessages(String currentUserId, String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList());
  }

  // Upload a file to Firebase Storage
  Future<String> uploadFile(String chatId, String messageId, File file) async {
    final ref = _storage.ref().child('chats/$chatId/$messageId');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Send a new message (text or media)
  Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String text,
    String? replyToMessageId,
    String messageType = 'text',
    File? mediaFile,
    String? fileName,
    int? duration,
  }) async {
    final chatId = getChatId(currentUserId, otherUserId);
    final messageId = const Uuid().v4();
    
    String? mediaUrl;
    if (mediaFile != null) {
      mediaUrl = await uploadFile(chatId, messageId, mediaFile);
    }
    
    final message = MessageModel(
      id: messageId,
      senderId: currentUserId,
      receiverId: otherUserId,
      text: text,
      createdAt: DateTime.now(),
      replyToMessageId: replyToMessageId,
      messageType: messageType,
      mediaUrl: mediaUrl,
      fileName: fileName,
      duration: duration,
    );

    // Batch write to update both the message and the lastMessage snippet in chat doc
    final batch = _firestore.batch();
    final chatDoc = _firestore.collection('chats').doc(chatId);
    final msgDoc = chatDoc.collection('messages').doc(messageId);

    batch.set(msgDoc, message.toJson());
    batch.set(chatDoc, {
      'participants': [currentUserId, otherUserId],
      'lastMessage': text,
      'lastMessageSenderId': currentUserId, // Added this field
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // Edit an existing message
  Future<void> editMessage(String currentUserId, String otherUserId, String messageId, String newText) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': newText,
      'isEdited': true,
    });
  }

  // Soft delete a message
  Future<void> deleteMessage(String currentUserId, String otherUserId, String messageId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': 'This message was deleted',
      'isDeleted': true,
      'isEdited': false,
    });
  }

  // Update read status for incoming messages
  Future<void> updateMessageReadStatus(String currentUserId, String otherUserId, String messageId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  // Stream typing status of the other user
  Stream<bool> getTypingStatus(String currentUserId, String otherUserId) {
    final chatId = getChatId(currentUserId, otherUserId);
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data()!;
      List<dynamic> typingUsers = data['typing'] ?? [];
      return typingUsers.contains(otherUserId);
    });
  }

  // Set typing status for the current user
  Future<void> setTypingStatus(String currentUserId, String otherUserId, bool isTyping) async {
    final chatId = getChatId(currentUserId, otherUserId);
    final chatDoc = _firestore.collection('chats').doc(chatId);
    
    if (isTyping) {
      await chatDoc.set({
        'typing': FieldValue.arrayUnion([currentUserId])
      }, SetOptions(merge: true));
    } else {
      await chatDoc.set({
        'typing': FieldValue.arrayRemove([currentUserId])
      }, SetOptions(merge: true));
    }
  }

  // Add a reaction to a message (using Firestore map dot-notation)
  Future<void> addReaction(String currentUserId, String otherUserId, String messageId, String emoji) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$currentUserId': emoji});
  }

  // Remove the current user's reaction from a message
  Future<void> removeReaction(String currentUserId, String otherUserId, String messageId) async {
    final chatId = getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$currentUserId': FieldValue.delete()});
  }

  // Get list of recent chats for a user, sorted locally to avoid needing a Firestore composite index
  Stream<List<Map<String, dynamic>>> getRecentChats(String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['chatId'] = doc.id;
        return data;
      }).toList();
      
      docs.sort((a, b) {
        final Timestamp? timeA = a['lastMessageTime'] as Timestamp?;
        final Timestamp? timeB = b['lastMessageTime'] as Timestamp?;
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        return timeB.compareTo(timeA); // descending
      });
      
      return docs;
    });
  }
}
