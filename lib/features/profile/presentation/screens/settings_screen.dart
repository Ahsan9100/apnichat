import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ListView(
      children: [
        // Profile Section
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Edit Profile'),
          subtitle: const Text('Update your name, bio, and picture'),
          onTap: () => context.push('/edit-profile'),
        ),
        const Divider(),

        // Dark Mode Toggle
        SwitchListTile(
          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          title: const Text('Dark Mode'),
          subtitle: Text(isDark ? 'Dark theme is on' : 'Light theme is on'),
          value: isDark,
          activeColor: AppColors.primaryColor,
          onChanged: (value) {
            ref.read(themeModeProvider.notifier).state =
                value ? ThemeMode.dark : ThemeMode.light;
          },
        ),
        const Divider(),

        // Notifications
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Message, group & call tones'),
          onTap: () {},
        ),
        const Divider(),

        // Logout
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.errorColor),
          title: const Text('Logout', style: TextStyle(color: AppColors.errorColor)),
          onTap: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
