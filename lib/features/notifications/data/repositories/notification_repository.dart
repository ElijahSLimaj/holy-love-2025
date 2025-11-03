import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _notificationsCollection = 'notifications';

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String> createNotification(NotificationItem notification) async {
    try {
      final notificationRef = _firestore.collection(_notificationsCollection).doc();
      final notificationWithId = notification.copyWith(id: notificationRef.id);

      await notificationRef.set(notificationWithId.toFirestore());

      debugPrint('Created notification: ${notificationRef.id}');
      return notificationRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  Future<void> createMatchNotification({
    required String userId,
    required String matchedUserId,
    required String matchedUserName,
    String? matchedUserPhoto,
  }) async {
    final notification = NotificationItem.createMatch(
      userId: userId,
      matchedUserId: matchedUserId,
      matchedUserName: matchedUserName,
      matchedUserPhoto: matchedUserPhoto,
    );

    await createNotification(notification);
  }

  Future<void> createMessageNotification({
    required String userId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    String? senderPhoto,
  }) async {
    final notification = NotificationItem.createMessage(
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      messagePreview: messagePreview,
      senderPhoto: senderPhoto,
    );

    await createNotification(notification);
  }

  Future<void> createLikeNotification({
    required String userId,
    required String likerId,
    required String likerName,
    String? likerPhoto,
  }) async {
    final notification = NotificationItem.createLike(
      userId: userId,
      likerId: likerId,
      likerName: likerName,
      likerPhoto: likerPhoto,
    );

    await createNotification(notification);
  }

  Future<void> createProfileViewNotification({
    required String userId,
    required String viewerId,
    required String viewerName,
    String? viewerPhoto,
  }) async {
    final notification = NotificationItem.createProfileView(
      userId: userId,
      viewerId: viewerId,
      viewerName: viewerName,
      viewerPhoto: viewerPhoto,
    );

    await createNotification(notification);
  }

  Stream<List<NotificationItem>> streamUserNotifications() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<List<NotificationItem>> getUserNotifications({int limit = 50}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NotificationItem.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  Stream<int> streamUnreadCount() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection(_notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});

      debugPrint('Marked notification as read: $notificationId');
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      debugPrint('Marked all notifications as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();

      debugPrint('Deleted notification: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteAllNotifications() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();

      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Deleted all notifications');
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
      rethrow;
    }
  }
}
