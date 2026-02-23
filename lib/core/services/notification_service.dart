import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:holy_love/features/main/presentation/pages/main_navigation_screen.dart';

/// Service for handling Firebase Cloud Messaging (FCM) push notifications
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _fcmTokensCollection = 'fcmTokens';
  static const String _usersCollection = 'users';

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize FCM and set up message handlers
  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    try {
      // Request notification permissions (iOS)
      await _requestPermissions();

      // Get and save FCM token
      await _saveFCMToken();

      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM token refreshed: $newToken');
        _saveFCMToken();
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Notification opened app from background: ${message.messageId}');
        _handleNotificationTap(message, navigatorKey);
      });

      // Check if app was opened from a terminated state notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App opened from terminated state: ${initialMessage.messageId}');
        // Wait a bit for the app to fully initialize before navigating
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage, navigatorKey);
        });
      }

      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions (iOS)
  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    }
  }

  /// Get FCM token and save to Firestore
  Future<void> _saveFCMToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('Cannot save FCM token: User not authenticated');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      debugPrint('Got FCM token: $token');

      // Save token to Firestore in user's fcmTokens subcollection
      final tokenDoc = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_fcmTokensCollection)
          .doc(token); // Use token as document ID to prevent duplicates

      await tokenDoc.set({
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.messageId}');
    debugPrint('Notification: ${message.notification?.title}');
    debugPrint('Data: ${message.data}');

    // The system will automatically show a notification banner on iOS/Android
    // We can optionally show an in-app notification here
  }

  /// Handle notification tap and navigate to appropriate screen
  void _handleNotificationTap(
    RemoteMessage message,
    GlobalKey<NavigatorState>? navigatorKey,
  ) {
    final data = message.data;
    final type = data['type'] as String?;

    if (navigatorKey == null || navigatorKey.currentContext == null) {
      debugPrint('Cannot navigate: Navigator context not available');
      return;
    }

    final context = navigatorKey.currentContext!;

    switch (type) {
      case 'message':
        _navigateToChat(context, data);
        break;
      case 'match':
        _navigateToMatch(context, data);
        break;
      case 'like':
        _navigateToNotifications(context);
        break;
      default:
        _navigateToNotifications(context);
    }
  }

  void _navigateToChat(BuildContext context, Map<String, dynamic> data) {
    debugPrint('Navigating to messages for conversation: ${data['conversationId']}');
    // Import needed: import 'package:holy_love/features/main/presentation/pages/main_navigation_screen.dart';
    // Navigate to main screen and switch to messages tab (index 2)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
    // TODO: Add deep link to specific conversation when navigation supports it
  }

  void _navigateToMatch(BuildContext context, Map<String, dynamic> data) {
    debugPrint('Navigating to match: ${data['matchedUserId']}');
    // Navigate to main screen and switch to matches tab (index 1)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
    // TODO: Add deep link to specific match profile when navigation supports it
  }

  void _navigateToNotifications(BuildContext context) {
    debugPrint('Navigating to notifications');
    // Navigate to main screen (will show notification badge)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  /// Delete FCM token (call on logout)
  Future<void> deleteFCMToken() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final token = await _messaging.getToken();
      if (token == null) return;

      // Delete token from Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_fcmTokensCollection)
          .doc(token)
          .delete();

      // Delete token from FCM
      await _messaging.deleteToken();

      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Subscribe to a topic (for broadcast notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }
}
