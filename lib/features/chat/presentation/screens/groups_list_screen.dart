import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';
import '../../../../core/constants/app_colors.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(child: Text('You are not part of any groups yet.'));
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.dividerLight,
                  backgroundImage: group.groupPicUrl.isNotEmpty 
                      ? NetworkImage(group.groupPicUrl) 
                      : null,
                  child: group.groupPicUrl.isEmpty 
                      ? const Icon(Icons.group, color: Colors.grey) 
                      : null,
                ),
                title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(group.lastMessage ?? 'Tap to chat', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  context.push('/group-chat', extra: group);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/create-group');
        },
        backgroundColor: AppColors.accentColor,
        child: const Icon(Icons.group_add, color: Colors.white),
      ),
    );
  }
}
