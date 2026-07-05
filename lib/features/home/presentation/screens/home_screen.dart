import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/screens/chats_list_screen.dart';
import '../../../chat/presentation/screens/groups_list_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';

// Provider to manage the selected index of the NavigationBar
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final List<Widget> screens = [
      const ChatsListScreen(),
      const GroupsListScreen(),
      const SettingsScreen(),
    ];

    final List<String> titles = [
      'Messages',
      'Communities',
      'Settings',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[currentIndex]),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: AppColors.primaryColor),
              onPressed: () => context.push('/search'),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: AppColors.primaryColor),
              onPressed: () {}, // Future options
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 10,
        indicatorColor: AppColors.primaryColor.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primaryColor),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: AppColors.primaryColor),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primaryColor),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: currentIndex == 0 || currentIndex == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                if (currentIndex == 1) context.push('/create-group');
              },
              icon: Icon(currentIndex == 0 ? Icons.edit_square : Icons.group_add),
              label: Text(currentIndex == 0 ? 'New Chat' : 'New Group', style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }
}
