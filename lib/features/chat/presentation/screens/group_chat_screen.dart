import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/group_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/message_bubble.dart';

class GroupChatScreen extends ConsumerWidget {
  final GroupModel group;

  const GroupChatScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(groupMessagesProvider(group.id));
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    
    // Quick local controller just for group input
    final textController = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.chatBackgroundLight,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () {
            context.push('/group-info', extra: group);
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.dividerLight,
                backgroundImage: group.groupPicUrl.isNotEmpty 
                    ? NetworkImage(group.groupPicUrl) 
                    : null,
                child: group.groupPicUrl.isEmpty 
                    ? const Icon(Icons.group, color: Colors.grey) 
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Tap here for group info',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(child: Text('Start chatting in this group!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                      otherUserId: group.id,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.withOpacity(0.1),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (textController.text.trim().isNotEmpty) {
                        ref.read(groupControllerProvider.notifier).sendGroupMessage(
                          group.id, 
                          textController.text.trim()
                        );
                        textController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
