import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final String userId;
  final int totalLikes;
  final int totalLikesReceived;
  final int totalMatches;
  final int profileViews;
  final int messagesReceived;
  final int messagesSent;
  final DateTime? lastActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;
  final bool isVerified;

  UserStats({
    required this.userId,
    this.totalLikes = 0,
    this.totalLikesReceived = 0,
    this.totalMatches = 0,
    this.profileViews = 0,
    this.messagesReceived = 0,
    this.messagesSent = 0,
    this.lastActive,
    required this.createdAt,
    required this.updatedAt,
    this.isPremium = false,
    this.isVerified = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalLikes': totalLikes,
      'totalLikesReceived': totalLikesReceived,
      'totalMatches': totalMatches,
      'profileViews': profileViews,
      'messagesReceived': messagesReceived,
      'messagesSent': messagesSent,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPremium': isPremium,
      'isVerified': isVerified,
    };
  }

  factory UserStats.fromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now();
    final lastActive = data['lastActive'] != null
        ? (data['lastActive'] as Timestamp).toDate()
        : null;

    return UserStats(
      userId: data['userId'] ?? '',
      totalLikes: data['totalLikes'] ?? 0,
      totalLikesReceived: data['totalLikesReceived'] ?? 0,
      totalMatches: data['totalMatches'] ?? 0,
      profileViews: data['profileViews'] ?? 0,
      messagesReceived: data['messagesReceived'] ?? 0,
      messagesSent: data['messagesSent'] ?? 0,
      lastActive: lastActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPremium: data['isPremium'] ?? false,
      isVerified: data['isVerified'] ?? false,
    );
  }

  UserStats copyWith({
    String? userId,
    int? totalLikes,
    int? totalLikesReceived,
    int? totalMatches,
    int? profileViews,
    int? messagesReceived,
    int? messagesSent,
    DateTime? lastActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPremium,
    bool? isVerified,
  }) {
    return UserStats(
      userId: userId ?? this.userId,
      totalLikes: totalLikes ?? this.totalLikes,
      totalLikesReceived: totalLikesReceived ?? this.totalLikesReceived,
      totalMatches: totalMatches ?? this.totalMatches,
      profileViews: profileViews ?? this.profileViews,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      messagesSent: messagesSent ?? this.messagesSent,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPremium: isPremium ?? this.isPremium,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  factory UserStats.create({required String userId}) {
    final now = DateTime.now();
    return UserStats(
      userId: userId,
      createdAt: now,
      updatedAt: now,
      lastActive: now,
    );
  }

  UserStats incrementLikes() {
    return copyWith(
      totalLikes: totalLikes + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats incrementLikesReceived() {
    return copyWith(
      totalLikesReceived: totalLikesReceived + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats incrementMatches() {
    return copyWith(
      totalMatches: totalMatches + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats incrementProfileViews() {
    return copyWith(
      profileViews: profileViews + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats incrementMessagesReceived() {
    return copyWith(
      messagesReceived: messagesReceived + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats incrementMessagesSent() {
    return copyWith(
      messagesSent: messagesSent + 1,
      updatedAt: DateTime.now(),
    );
  }

  UserStats updateLastActive() {
    return copyWith(
      lastActive: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
