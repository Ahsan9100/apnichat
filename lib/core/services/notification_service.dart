import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/models/user_model.dart';

/// A global navigator key so NotificationService can navigate
/// without needing a BuildContext.
final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();

/// NotificationService is a singleton that handles all FCM-related setup
/// across all three app states: Foreground, Background, and Killed.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot>? _chatSubscription;
  StreamSubscription<QuerySnapshot>? _groupSubscription;
  DateTime? _listenerStartTime;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'apnichat_high_importance_channel',
    'ApniChat Notifications',
    description: 'This channel is used for important chat notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    await _requestPermissions();
    await _setupLocalNotifications();
    await _createAndroidChannel();
    _setupForegroundMessageHandler();
    _setupNotificationOpenedHandlers();
  }

  Future<void> _requestPermissions() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOSInit = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iOSInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped a foreground local notification
        final payload = response.payload;
        debugPrint('🔔 Local notification tapped. Payload: $payload');
        if (payload != null && payload.isNotEmpty) {
          _navigateToChatByUserId(payload);
        }
      },
    );
  }

  Future<void> _createAndroidChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  /// Handles FCM messages received while the app is in the FOREGROUND.
  /// Shows a local notification since FCM does not display one automatically.
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        final senderId = message.data['senderId'] ?? '';
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          // Payload = senderId so we can open the correct chat on tap
          payload: senderId,
        );
      }
    });
  }

  /// Handles tapping a notification while the app is in the BACKGROUND (not killed).
  void _setupNotificationOpenedHandlers() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Background notification tapped.');
      _handleNotificationNavigation(message);
    });
  }

  /// Handles tapping a notification that launched the app from KILLED state.
  Future<void> handleInitialMessage() async {
    final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 App launched via notification.');
      // Small delay to ensure the navigator is ready
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationNavigation(initialMessage);
    }
  }

  /// Central method: parse data from the FCM message and navigate.
  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final senderId = data['senderId'] ?? '';
    debugPrint('🔔 Navigating to chat. senderId=$senderId');
    if (senderId.isNotEmpty) {
      _navigateToChatByUserId(senderId);
    }
  }

  /// Fetches the sender's UserModel from Firestore and navigates to /chat.
  Future<void> _navigateToChatByUserId(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ User $userId not found in Firestore.');
        return;
      }

      final data = doc.data()!;
      // Safety: older users may not have a name field
      if (data['name'] == null) {
        data['name'] = data['email']?.toString().split('@').first ?? 'Unknown';
      }

      final user = UserModel.fromJson(data);

      final navigator = notificationNavigatorKey.currentState;
      if (navigator != null) {
        // Push the chat screen on top of whatever is currently shown
        navigator.pushNamed('/chat', arguments: user);
      } else {
        debugPrint('⚠️ Navigator not ready yet.');
      }
    } catch (e) {
      debugPrint('❌ Error navigating to chat: $e');
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  void listenTokenRefresh(String userId) {
    _fcm.onTokenRefresh.listen((newToken) async {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': newToken});
    });
  }

  Future<void> saveTokenToFirestore(String userId) async {
    final token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
      listenTokenRefresh(userId);
    }
  }

  // ==========================================
  // FOREGROUND / BACKGROUND LOCAL LISTENERS
  // ==========================================
  
  void startMessageListener(String currentUserId) {
    _listenerStartTime = DateTime.now();
    debugPrint('🔔 Starting local message listeners for $currentUserId');

    // 1. Listen to One-to-One Chats
    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final String? senderId = data['lastMessageSenderId'];
          final Timestamp? timestamp = data['lastMessageTime'];
          final String lastMessage = data['lastMessage'] ?? 'New Message';

          if (senderId != null && senderId != currentUserId && timestamp != null) {
            if (timestamp.toDate().isAfter(_listenerStartTime!)) {
              // Try to get sender's name
              String senderName = 'New Message';
              try {
                final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
                if (userDoc.exists) {
                  senderName = userDoc.data()?['name'] ?? userDoc.data()?['email']?.toString().split('@').first ?? 'Someone';
                }
              } catch (_) {}

              _showLocalNotification(
                title: senderName,
                body: lastMessage,
                payload: senderId,
              );
            }
          }
        }
      }
    });

    // 2. Listen to Groups
    _groupSubscription?.cancel();
    _groupSubscription = FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final String? senderId = data['lastMessageSenderId'];
          final Timestamp? timestamp = data['lastMessageTime'];
          final String lastMessage = data['lastMessage'] ?? 'New Message';
          final String groupName = data['name'] ?? 'Group';

          if (senderId != null && senderId != currentUserId && timestamp != null) {
            if (timestamp.toDate().isAfter(_listenerStartTime!)) {
              _showLocalNotification(
                title: groupName,
                body: lastMessage,
                payload: data['id'] ?? '', // Pass groupId
              );
            }
          }
        }
      }
    });
  }

  void stopMessageListener() {
    debugPrint('🔔 Stopping local message listeners');
    _chatSubscription?.cancel();
    _groupSubscription?.cancel();
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }
}
