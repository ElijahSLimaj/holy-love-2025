import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  match,
  message,
  like,
  profileView,
  system,
}

class NotificationItem {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedUserId;
  final String? relatedUserName;
  final String? relatedUserPhoto;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.relatedUserId,
    this.relatedUserName,
    this.relatedUserPhoto,
    this.actionUrl,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'relatedUserId': relatedUserId,
      'relatedUserName': relatedUserName,
      'relatedUserPhoto': relatedUserPhoto,
      'actionUrl': actionUrl,
      'metadata': metadata,
    };
  }

  factory NotificationItem.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    return NotificationItem(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.system,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: timestamp,
      isRead: data['isRead'] ?? false,
      relatedUserId: data['relatedUserId'],
      relatedUserName: data['relatedUserName'],
      relatedUserPhoto: data['relatedUserPhoto'],
      actionUrl: data['actionUrl'],
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  NotificationItem copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? relatedUserId,
    String? relatedUserName,
    String? relatedUserPhoto,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedUserName: relatedUserName ?? this.relatedUserName,
      relatedUserPhoto: relatedUserPhoto ?? this.relatedUserPhoto,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NotificationItem.createMatch({
    required String userId,
    required String matchedUserId,
    required String matchedUserName,
    String? matchedUserPhoto,
  }) {
    return NotificationItem(
      id: '',
      userId: userId,
      type: NotificationType.match,
      title: 'New Match!',
      message: 'You and $matchedUserName matched!',
      timestamp: DateTime.now(),
      relatedUserId: matchedUserId,
      relatedUserName: matchedUserName,
      relatedUserPhoto: matchedUserPhoto,
    );
  }

  factory NotificationItem.createMessage({
    required String userId,
    required String senderId,
    required String senderName,
    required String messagePreview,
    String? senderPhoto,
  }) {
    return NotificationItem(
      id: '',
      userId: userId,
      type: NotificationType.message,
      title: 'New Message',
      message: '$senderName: $messagePreview',
      timestamp: DateTime.now(),
      relatedUserId: senderId,
      relatedUserName: senderName,
      relatedUserPhoto: senderPhoto,
    );
  }

  factory NotificationItem.createLike({
    required String userId,
    required String likerId,
    required String likerName,
    String? likerPhoto,
  }) {
    return NotificationItem(
      id: '',
      userId: userId,
      type: NotificationType.like,
      title: 'Someone Likes You!',
      message: '$likerName likes your profile',
      timestamp: DateTime.now(),
      relatedUserId: likerId,
      relatedUserName: likerName,
      relatedUserPhoto: likerPhoto,
    );
  }

  factory NotificationItem.createProfileView({
    required String userId,
    required String viewerId,
    required String viewerName,
    String? viewerPhoto,
  }) {
    return NotificationItem(
      id: '',
      userId: userId,
      type: NotificationType.profileView,
      title: 'Profile View',
      message: '$viewerName viewed your profile',
      timestamp: DateTime.now(),
      relatedUserId: viewerId,
      relatedUserName: viewerName,
      relatedUserPhoto: viewerPhoto,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
