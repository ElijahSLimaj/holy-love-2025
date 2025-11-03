import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

enum MessageType {
  text,
  image,
  prayer,
  bibleVerse,
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final Map<String, dynamic>? metadata;
  final String? imageUrl;
  final String? thumbnailUrl;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.status,
    required this.timestamp,
    this.readAt,
    this.deliveredAt,
    this.metadata,
    this.imageUrl,
    this.thumbnailUrl,
  });

  bool get isRead => status == MessageStatus.read;
  bool get isDelivered => status == MessageStatus.delivered || isRead;
  bool get isSent => status != MessageStatus.sending && status != MessageStatus.failed;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'metadata': metadata,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();
    final readAt = data['readAt'] != null
        ? (data['readAt'] as Timestamp).toDate()
        : null;
    final deliveredAt = data['deliveredAt'] != null
        ? (data['deliveredAt'] as Timestamp).toDate()
        : null;

    return ChatMessage(
      id: data['id'] ?? '',
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: timestamp,
      readAt: readAt,
      deliveredAt: deliveredAt,
      metadata: data['metadata'] as Map<String, dynamic>?,
      imageUrl: data['imageUrl'],
      thumbnailUrl: data['thumbnailUrl'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    DateTime? readAt,
    DateTime? deliveredAt,
    Map<String, dynamic>? metadata,
    String? imageUrl,
    String? thumbnailUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      readAt: readAt ?? this.readAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      metadata: metadata ?? this.metadata,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
