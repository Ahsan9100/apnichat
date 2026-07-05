import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/user_actions_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_field.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _isSearching = false;

  void _showReportSheet(BuildContext context) {
    final reasons = ['Spam', 'Abuse or Harassment', 'Fake Account', 'Hate Speech', 'Other'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Report User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          ...reasons.map((r) => ListTile(
                title: Text(r),
                onTap: () {
                  ref.read(userActionsControllerProvider).reportUser(widget.otherUser.id, r);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User reported. Thank you.')));
                },
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.otherUser.id));
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isTypingAsync = ref.watch(typingStatusProvider(widget.otherUser.id));
    final isBlockedAsync = ref.watch(isBlockedProvider(widget.otherUser.id));
    final searchQuery = ref.watch(searchInChatQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.chatBackgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (v) => ref.read(searchInChatQueryProvider.notifier).state = v,
              )
            : Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.dividerLight,
                    backgroundImage: widget.otherUser.profilePicUrl.isNotEmpty
                        ? NetworkImage(widget.otherUser.profilePicUrl)
                        : null,
                    child: widget.otherUser.profilePicUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.otherUser.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        isTypingAsync.when(
                          data: (isTyping) => Text(
                            isTyping ? 'typing...' : (widget.otherUser.isOnline ? 'Online' : 'Offline'),
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) ref.read(searchInChatQueryProvider.notifier).state = '';
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'block') {
                isBlockedAsync.when(
                  data: (blocked) => blocked
                      ? ref.read(userActionsControllerProvider).unblockUser(widget.otherUser.id)
                      : ref.read(userActionsControllerProvider).blockUser(widget.otherUser.id),
                  loading: () {},
                  error: (_, __) {},
                );
              } else if (val == 'report') {
                _showReportSheet(context);
              } else if (val == 'archive') {
                final chatId = ref.read(chatRepositoryProvider).getChatId(currentUserId, widget.otherUser.id);
                ref.read(userActionsControllerProvider).archiveChat(chatId);
                context.pop();
              } else if (val == 'pin') {
                final chatId = ref.read(chatRepositoryProvider).getChatId(currentUserId, widget.otherUser.id);
                ref.read(userActionsControllerProvider).pinChat(chatId);
              }
            },
            itemBuilder: (context) {
              final isBlocked = isBlockedAsync.value ?? false;
              return [
                PopupMenuItem(value: 'block', child: Text(isBlocked ? 'Unblock' : 'Block')),
                const PopupMenuItem(value: 'report', child: Text('Report')),
                const PopupMenuItem(value: 'archive', child: Text('Archive Chat')),
                const PopupMenuItem(value: 'pin', child: Text('Pin Chat')),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                final filtered = ref.read(filteredMessagesProvider(messages));
                if (filtered.isEmpty) {
                  return Center(child: Text(searchQuery.isNotEmpty ? 'No messages found' : 'Say Hi! 👋'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final message = filtered[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                      otherUserId: widget.otherUser.id,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
          isBlockedAsync.when(
            data: (isBlocked) => isBlocked
                ? Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade200,
                    child: const Center(child: Text('You have blocked this user. Unblock to send messages.')),
                  )
                : ChatInputField(otherUserId: widget.otherUser.id),
            loading: () => ChatInputField(otherUserId: widget.otherUser.id),
            error: (_, __) => ChatInputField(otherUserId: widget.otherUser.id),
          ),
        ],
      ),
    );
  }
}
