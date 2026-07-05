import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/group_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/group_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GroupInfoScreen extends ConsumerWidget {
  final GroupModel group;

  const GroupInfoScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';
    final isCurrentUserAdmin = group.adminIds.contains(currentUserId);
    final isCurrentUserOwner = group.ownerId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.dividerLight,
                backgroundImage: group.groupPicUrl.isNotEmpty 
                    ? NetworkImage(group.groupPicUrl) 
                    : null,
                child: group.groupPicUrl.isEmpty 
                    ? const Icon(Icons.group, size: 60, color: Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Group • ${group.memberIds.length} members'),
            const SizedBox(height: 20),
            Container(color: AppColors.dividerLight, height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text('${group.memberIds.length} members', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.memberIds.length,
              itemBuilder: (context, index) {
                final memberId = group.memberIds[index];
                final isOwner = group.ownerId == memberId;
                final isAdmin = group.adminIds.contains(memberId);
                
                // For a full app, you would fetch the user's details based on memberId.
                // Here we just display their ID and Roles.
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(memberId == currentUserId ? 'You' : 'User $memberId'),
                  subtitle: Text(
                    isOwner ? 'Owner' : (isAdmin ? 'Admin' : 'Member'),
                    style: TextStyle(color: isOwner || isAdmin ? AppColors.accentColor : Colors.grey),
                  ),
                  onTap: () {
                    // Show options if current user is admin/owner and not clicking themselves
                    if ((isCurrentUserAdmin || isCurrentUserOwner) && memberId != currentUserId) {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCurrentUserOwner && !isAdmin)
                              ListTile(
                                leading: const Icon(Icons.security),
                                title: const Text('Make Admin'),
                                onTap: () {
                                  ref.read(groupControllerProvider.notifier).makeAdmin(group.id, memberId);
                                  Navigator.pop(ctx);
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.remove_circle, color: AppColors.errorColor),
                              title: const Text('Remove from Group', style: TextStyle(color: AppColors.errorColor)),
                              onTap: () {
                                ref.read(groupControllerProvider.notifier).removeMember(group.id, memberId);
                                Navigator.pop(ctx);
                              },
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
