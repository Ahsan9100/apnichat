import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message_model.dart';
import '../../data/repositories/user_actions_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ──────────────── BLOCK PROVIDER ────────────────

final isBlockedProvider = StreamProvider.family<bool, String>((ref, targetUserId) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  return ref.watch(userActionsRepositoryProvider).isUserBlocked(currentUserId, targetUserId);
});

// ──────────────── PIN PROVIDER ────────────────

final pinnedChatsProvider = StreamProvider<List<String>>((ref) {
  final currentUserId = ref.watch(authStateProvider).value?.uid;
  if (currentUserId == null) return const Stream.empty();
  return ref.watch(userActionsRepositoryProvider).getPinnedChats(currentUserId);
});

// ──────────────── SEARCH IN CHAT PROVIDER ────────────────

final searchInChatQueryProvider = StateProvider<String>((ref) => '');

final filteredMessagesProvider = Provider.family<List<MessageModel>, List<MessageModel>>((ref, allMessages) {
  final query = ref.watch(searchInChatQueryProvider);
  if (query.isEmpty) return allMessages;
  return allMessages.where((m) => m.text.toLowerCase().contains(query.toLowerCase())).toList();
});

// ──────────────── USER ACTIONS CONTROLLER ────────────────

final userActionsControllerProvider = Provider<UserActionsController>((ref) {
  return UserActionsController(ref.watch(userActionsRepositoryProvider), ref.watch(chatRepositoryProvider), ref);
});

class UserActionsController {
  final UserActionsRepository _actionsRepo;
  final ChatRepository _chatRepo;
  final Ref _ref;

  UserActionsController(this._actionsRepo, this._chatRepo, this._ref);

  String get _currentUserId => _ref.read(authStateProvider).value?.uid ?? '';

  Future<void> blockUser(String targetUserId) =>
      _actionsRepo.blockUser(_currentUserId, targetUserId);

  Future<void> unblockUser(String targetUserId) =>
      _actionsRepo.unblockUser(_currentUserId, targetUserId);

  Future<void> reportUser(String targetUserId, String reason) =>
      _actionsRepo.reportUser(reporterId: _currentUserId, reportedId: targetUserId, reason: reason);

  Future<void> pinChat(String chatId) =>
      _actionsRepo.pinChat(_currentUserId, chatId);

  Future<void> unpinChat(String chatId) =>
      _actionsRepo.unpinChat(_currentUserId, chatId);

  Future<void> archiveChat(String chatId) =>
      _actionsRepo.archiveChat(_currentUserId, chatId);

  Future<void> unarchiveChat(String chatId) =>
      _actionsRepo.unarchiveChat(_currentUserId, chatId);

  Future<void> addReaction(String otherUserId, String messageId, String emoji) =>
      _chatRepo.addReaction(_currentUserId, otherUserId, messageId, emoji);

  Future<void> removeReaction(String otherUserId, String messageId) =>
      _chatRepo.removeReaction(_currentUserId, otherUserId, messageId);
}
