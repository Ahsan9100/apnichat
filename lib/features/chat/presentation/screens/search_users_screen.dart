import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../../../core/constants/app_colors.dart';

class SearchUsersScreen extends ConsumerWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchUsersProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: searchResults.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                searchQuery.isEmpty ? 'Type a name to search' : 'No users found',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.dividerLight,
                  backgroundImage: user.profilePicUrl.isNotEmpty 
                      ? NetworkImage(user.profilePicUrl) 
                      : null,
                  child: user.profilePicUrl.isEmpty 
                      ? const Icon(Icons.person, color: Colors.grey) 
                      : null,
                ),
                title: Text(user.name.isEmpty ? 'Unknown' : user.name),
                subtitle: Text(user.bio, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  context.push('/chat', extra: user);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
