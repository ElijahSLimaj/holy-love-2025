import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/conversation_data.dart';

class MessageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _conversationsCollection = 'conversations';
  static const String _messagesSubcollection = 'messages';

  MessageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String generateConversationId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  Future<ConversationData> createConversation({
    required String otherUserId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final conversationId = generateConversationId(userId, otherUserId);
    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);

    final existingConversation = await conversationRef.get();
    if (existingConversation.exists) {
      return ConversationData.fromFirestore(existingConversation.data()!);
    }

    final conversation = ConversationData.create(
      id: conversationId,
      participants: [userId, otherUserId],
    );

    await conversationRef.set(conversation.toFirestore());

    return conversation;
  }

  Future<ConversationData?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();

      if (!doc.exists) return null;
      return ConversationData.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }

  Stream<ConversationData?> streamConversation(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return ConversationData.fromFirestore(snapshot.data()!);
    });
  }

  Stream<List<ConversationData>> streamUserConversations() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationData.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<String> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    final messageId = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc()
        .id;

    final message = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: userId,
      receiverId: receiverId,
      text: text,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    final messageRef = _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .doc(messageId);

    batch.set(messageRef, message.toFirestore());

    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);

    final currentUnreadCounts = await conversationRef
        .get()
        .then((doc) => doc.data()?['unreadCounts'] as Map<String, dynamic>? ?? {});

    final newUnreadCount = (currentUnreadCounts[receiverId] ?? 0) + 1;

    batch.update(conversationRef, {
      'lastMessage': text,
      'lastMessageSenderId': userId,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadCounts.$receiverId': newUnreadCount,
    });

    await batch.commit();

    return messageId;
  }

  Stream<List<ChatMessage>> streamMessages(String conversationId) {
    return _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc.data()))
          .toList();
    });
  }

  Future<void> markMessagesAsRead({
    required String conversationId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final batch = _firestore.batch();

    final conversationRef =
        _firestore.collection(_conversationsCollection).doc(conversationId);

    batch.update(conversationRef, {
      'unreadCounts.$userId': 0,
      'lastReadAt.$userId': FieldValue.serverTimestamp(),
    });

    final messagesSnapshot = await _firestore
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection(_messagesSubcollection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: MessageStatus.delivered.name)
        .get();

    for (var doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {
        'status': MessageStatus.read.name,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> markMessageAsDelivered(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .collection(_messagesSubcollection)
          .doc(messageId)
          .update({
        'status': MessageStatus.delivered.name,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking message as delivered: $e');
    }
  }

  Future<void> setTypingStatus({
    required String conversationId,
    required bool isTyping,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'typing.$userId': isTyping,
      });
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  Future<int> getUnreadCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final unreadCounts = doc.data()['unreadCounts'] as Map<String, dynamic>?;
        totalUnread += (unreadCounts?[userId] ?? 0) as int;
      }

      return totalUnread;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final batch = _firestore.batch();

      final conversationRef =
          _firestore.collection(_conversationsCollection).doc(conversationId);

      batch.update(conversationRef, {'isActive': false});

      await batch.commit();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  Future<List<ConversationData>> getRecentConversations({int limit = 5}) async {
    final userId = currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_conversationsCollection)
          .where('participants', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('lastMessageAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ConversationData.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent conversations: $e');
      return [];
    }
  }
}
