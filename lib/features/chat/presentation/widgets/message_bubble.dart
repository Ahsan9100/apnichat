import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/user_actions_provider.dart';

class MessageBubble extends ConsumerWidget {
  final MessageModel message;
  final bool isMe;
  final String otherUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserId,
  });

  void _showOptions(BuildContext context, WidgetRef ref) {
    if (message.isDeleted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji reaction row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['👍', '❤️', '😂', '😮', '😢', '🙏'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(userActionsControllerProvider).addReaction(otherUserId, message.id, emoji);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(replyingToMessageProvider.notifier).state = message;
                },
              ),
              if (isMe && message.messageType == 'text')
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(context, ref);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Forward'),
                onTap: () => Navigator.pop(context),
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.errorColor),
                  title: const Text('Delete', style: TextStyle(color: AppColors.errorColor)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(chatControllerProvider).deleteMessage(otherUserId, message.id);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(chatControllerProvider).editMessage(otherUserId, message.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (message.isDeleted) {
      return Text('This message was deleted',
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontStyle: FontStyle.italic));
    }
    switch (message.messageType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(message.mediaUrl ?? '', width: 200, height: 200, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 80)),
        );
      case 'video':
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200, height: 150,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
            Positioned(
              bottom: 6, left: 8,
              child: Text('🎥 Video', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        );
      case 'document':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.insert_drive_file, size: 36, color: Colors.indigo),
          const SizedBox(width: 8),
          Flexible(child: Text(message.fileName ?? 'Document',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)),
        ]);
      case 'audio':
        return Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(backgroundColor: isMe ? Colors.white24 : AppColors.primaryColor,
              child: const Icon(Icons.play_arrow, color: Colors.white)),
          const SizedBox(width: 8),
          Container(width: 80, height: 4, color: isMe ? Colors.white54 : Colors.black26),
          const SizedBox(width: 8),
          Text('0:00', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
        ]);
      default:
        return Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87));
    }
  }

  Widget _buildReactions(WidgetRef ref) {
    if (message.reactions.isEmpty) return const SizedBox.shrink();
    // Group same emojis and count them
    final Map<String, int> counts = {};
    for (final emoji in message.reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: counts.entries.map((e) {
          return GestureDetector(
            onTap: () => ref.read(userActionsControllerProvider).removeReaction(otherUserId, message.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text('${e.key} ${e.value}', style: const TextStyle(fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isMe && !message.isRead && !message.isDeleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatControllerProvider).markAsRead(otherUserId, message.id);
      });
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showOptions(context, ref),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isMe && !message.isDeleted
                      ? const LinearGradient(
                          colors: [AppColors.primaryColor, AppColors.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isMe
                      ? (message.isDeleted ? Colors.grey.shade400 : null)
                      : (message.isDeleted ? Colors.grey.shade300 : Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isMe ? AppColors.primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.replyToMessageId != null && !message.isDeleted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Text(
                          'Replied to a message...', 
                          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.white70)
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(child: _buildMediaContent()),
                        const SizedBox(width: 12),
                        Text(
                          '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white70 : AppColors.textSecondaryLight
                          ),
                        ),
                        if (message.isEdited && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)', 
                            style: TextStyle(
                              fontSize: 10, 
                              fontStyle: FontStyle.italic, 
                              color: isMe ? Colors.white70 : AppColors.textSecondaryLight
                            )
                          ),
                        ],
                        if (isMe && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done, 
                            size: 14,
                            color: message.isRead ? Colors.lightBlueAccent : Colors.white70
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildReactions(ref),
            ],
          ),
        ),
      ),
    );
  }
}
