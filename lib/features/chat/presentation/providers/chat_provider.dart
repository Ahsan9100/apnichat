import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../../core/models/user_model.dart';

// Provides the stream of messages for a given chat
final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, otherUserId) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(currentUserId, otherUserId);
});

// Provides typing status of the other user
final typingStatusProvider = StreamProvider.family<bool, String>((ref, otherUserId) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getTypingStatus(currentUserId, otherUserId);
});

// Provides the stream of recent chats for the current user
final recentChatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getRecentChats(currentUserId);
});

// Provides the profile of the other participant in a chat
final chatParticipantProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUser(userId);
});

// StateProvider to hold the message we are currently replying to
final replyingToMessageProvider = StateProvider<MessageModel?>((ref) => null);

// Controller for chat actions
final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider), ref);
});

class ChatController {
  final ChatRepository _repository;
  final Ref _ref;

  ChatController(this._repository, this._ref);

  Future<void> sendMessage({
    required String otherUserId,
    required String text,
    String messageType = 'text',
    File? mediaFile,
    String? fileName,
    int? duration,
  }) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;

    final replyingTo = _ref.read(replyingToMessageProvider);

    await _repository.sendMessage(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
      text: text,
      replyToMessageId: replyingTo?.id,
      messageType: messageType,
      mediaFile: mediaFile,
      fileName: fileName,
      duration: duration,
    );

    // Clear reply state after sending
    _ref.read(replyingToMessageProvider.notifier).state = null;
  }

  Future<void> setTypingStatus(String otherUserId, bool isTyping) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;
    await _repository.setTypingStatus(currentUserId, otherUserId, isTyping);
  }

  Future<void> deleteMessage(String otherUserId, String messageId) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;
    await _repository.deleteMessage(currentUserId, otherUserId, messageId);
  }

  Future<void> editMessage(String otherUserId, String messageId, String newText) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;
    await _repository.editMessage(currentUserId, otherUserId, messageId, newText);
  }

  Future<void> markAsRead(String otherUserId, String messageId) async {
    final currentUserId = _ref.read(authStateProvider).value?.uid;
    if (currentUserId == null) return;
    await _repository.updateMessageReadStatus(currentUserId, otherUserId, messageId);
  }
}
