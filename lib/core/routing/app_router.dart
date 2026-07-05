import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chat/presentation/screens/search_users_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/chat/presentation/screens/create_group_screen.dart';
import '../../features/chat/presentation/screens/group_chat_screen.dart';
import '../../features/chat/presentation/screens/group_info_screen.dart';
import '../../core/models/user_model.dart';
import '../../core/models/group_model.dart';
import '../../core/services/notification_service.dart';

/// Provider for GoRouter to enable navigation based on Auth state changes
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    // ✅ Use the global navigator key so NotificationService can navigate
    navigatorKey: notificationNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      // If auth state is still loading, stay on splash screen
      if (authState.isLoading) return '/splash';

      final isAuth = authState.value != null;
      final isLoggingIn = state.uri.toString() == '/login' || 
                          state.uri.toString() == '/signup' || 
                          state.uri.toString() == '/forgot-password';

      if (!isAuth && !isLoggingIn) {
        // Redirect to login if unauthenticated and trying to access restricted routes
        return '/login';
      }

      if (isAuth && (isLoggingIn || state.uri.toString() == '/splash')) {
        // Redirect to home if authenticated and trying to access auth screens
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchUsersScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          // Support both GoRouter extra (push via context.push) and
          // Navigator arguments (push via notificationNavigatorKey)
          final extra = state.extra;
          final args = ModalRoute.of(context)?.settings.arguments;
          final user = (extra as UserModel?) ?? (args as UserModel?);
          if (user == null) {
            return const Scaffold(
              body: Center(child: Text('User not found')),
            );
          }
          return ChatScreen(otherUser: user);
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/group-chat',
        builder: (context, state) {
          final group = state.extra as GroupModel;
          return GroupChatScreen(group: group);
        },
      ),
      GoRoute(
        path: '/group-info',
        builder: (context, state) {
          final group = state.extra as GroupModel;
          return GroupInfoScreen(group: group);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.error}'),
      ),
    ),
  );
});
