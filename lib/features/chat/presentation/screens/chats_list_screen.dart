import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/chat_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentChatsAsync = ref.watch(recentChatsProvider);
    final currentUserId = ref.watch(authStateProvider).value?.uid;

    return recentChatsAsync.when(
      data: (chats) {
        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppColors.textSecondaryLight.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet.',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for a user to start chatting!',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100), // padding for FAB
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final participants = List<String>.from(chat['participants'] ?? []);
            
            // Find the other user's ID
            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            
            if (otherUserId.isEmpty) return const SizedBox.shrink();

            final lastMessage = chat['lastMessage'] ?? 'Attachment';
            final Timestamp? timestamp = chat['lastMessageTime'];
            String timeText = '';
            
            if (timestamp != null) {
              final date = timestamp.toDate();
              final now = DateTime.now();
              if (date.year == now.year && date.month == now.month && date.day == now.day) {
                timeText = DateFormat('h:mm a').format(date);
              } else {
                timeText = DateFormat('MMM d').format(date);
              }
            }

            // Fetch the other user's profile
            final otherUserAsync = ref.watch(chatParticipantProvider(otherUserId));

            return otherUserAsync.when(
              data: (otherUser) {
                if (otherUser == null) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                        backgroundImage: otherUser.profilePicUrl.isNotEmpty 
                            ? NetworkImage(otherUser.profilePicUrl) 
                            : null,
                        child: otherUser.profilePicUrl.isEmpty 
                            ? const Icon(Icons.person, color: AppColors.primaryColor) 
                            : null,
                      ),
                    ),
                    title: Text(
                      otherUser.name.isEmpty ? 'Unknown' : otherUser.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    trailing: timeText.isNotEmpty 
                        ? Text(
                            timeText, 
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            )
                          )
                        : null,
                    onTap: () {
                      context.push('/chat', extra: otherUser);
                    },
                  ),
                );
              },
              loading: () => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}
