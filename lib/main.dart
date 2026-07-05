import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/error_handler.dart';
import 'core/services/notification_service.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart'; // Added import
import 'firebase_options.dart';

/// IMPORTANT: This function MUST be a top-level function (not inside a class).
/// It handles FCM messages when the app is in BACKGROUND or KILLED/TERMINATED state.
/// The @pragma annotation ensures this function is not removed during AOT compilation.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized even when app is killed
  await Firebase.initializeApp();
  debugPrint('🔔 Background notification received: ${message.notification?.title}');
  // No need to show a notification here — FCM does it automatically
  // from the notification payload in the background/killed state.
}

void main() async {
  // Ensure that plugin services are initialized before `runApp`
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    ErrorHandler.handleError(e, stackTrace);
  }

  // ✅ Register the top-level background handler for FCM
  // This MUST be called before runApp()
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Initialize the NotificationService (sets up local notifications, permissions, etc.)
  await NotificationService.instance.initialize();

  // ✅ Handle the case where the app was KILLED and user tapped a notification to open it
  await NotificationService.instance.handleInitialMessage();

  // Wrap the app with ProviderScope for Riverpod state management
  runApp(const ProviderScope(child: ApniChatApp()));
}

/// The root widget of the application.
class ApniChatApp extends ConsumerWidget {
  const ApniChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Auth state changes to start/stop local message listener
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        NotificationService.instance.startMessageListener(user.uid);
      } else {
        NotificationService.instance.stopMessageListener();
      }
    });

    // Retrieve the GoRouter instance from Riverpod provider
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'ApniChat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: router,
      // ✅ Attach the global navigator key so NotificationService
      //    can navigate when a notification is tapped
      // Note: GoRouter manages its own navigator internally.
      // We wire it up via the router's navigatorKey below.
    );
  }
}
