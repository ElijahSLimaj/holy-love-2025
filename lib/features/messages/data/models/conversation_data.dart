import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationData {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final Map<String, DateTime> lastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, bool>? typing;

  ConversationData({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.unreadCounts,
    required this.lastReadAt,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.typing,
  });

  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  bool isTyping(String userId) => typing?[userId] ?? false;

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'unreadCounts': unreadCounts,
      'lastReadAt': lastReadAt.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'typing': typing ?? {},
    };
  }

  factory ConversationData.fromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now();
    final lastMessageAt = data['lastMessageAt'] != null
        ? (data['lastMessageAt'] as Timestamp).toDate()
        : null;

    final unreadCountsData = data['unreadCounts'] as Map<String, dynamic>? ?? {};
    final unreadCounts = unreadCountsData.map(
      (key, value) => MapEntry(key, value as int),
    );

    final lastReadAtData = data['lastReadAt'] as Map<String, dynamic>? ?? {};
    final lastReadAt = lastReadAtData.map(
      (key, value) => MapEntry(key, (value as Timestamp).toDate()),
    );

    final typingData = data['typing'] as Map<String, dynamic>? ?? {};
    final typing = typingData.map(
      (key, value) => MapEntry(key, value as bool),
    );

    return ConversationData(
      id: data['id'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageAt: lastMessageAt,
      unreadCounts: unreadCounts,
      lastReadAt: lastReadAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: data['isActive'] ?? true,
      typing: typing,
    );
  }

  ConversationData copyWith({
    String? id,
    List<String>? participants,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    Map<String, int>? unreadCounts,
    Map<String, DateTime>? lastReadAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, bool>? typing,
  }) {
    return ConversationData(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      typing: typing ?? this.typing,
    );
  }

  factory ConversationData.create({
    required String id,
    required List<String> participants,
  }) {
    final now = DateTime.now();
    return ConversationData(
      id: id,
      participants: participants,
      unreadCounts: {for (var p in participants) p: 0},
      lastReadAt: {for (var p in participants) p: now},
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
