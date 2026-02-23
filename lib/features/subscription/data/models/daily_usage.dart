import 'package:cloud_firestore/cloud_firestore.dart';

class DailyUsage {
  final String id;
  final String userId;
  final String date;
  final int profileViews;
  final int likes;
  final int passes;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const int freeProfileViewsLimit = 5;
  static const int freeLikesLimit = 5;
  static const int freePassesLimit = 5;

  DailyUsage({
    required this.id,
    required this.userId,
    required this.date,
    this.profileViews = 0,
    this.likes = 0,
    this.passes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canViewProfile => profileViews < freeProfileViewsLimit;
  bool get canLike => likes < freeLikesLimit;
  bool get canPass => passes < freePassesLimit;

  int get remainingProfileViews =>
      (freeProfileViewsLimit - profileViews).clamp(0, freeProfileViewsLimit);
  int get remainingLikes =>
      (freeLikesLimit - likes).clamp(0, freeLikesLimit);
  int get remainingPasses =>
      (freePassesLimit - passes).clamp(0, freePassesLimit);

  factory DailyUsage.create({required String userId, required String date}) {
    final now = DateTime.now();
    return DailyUsage(
      id: '${userId}_$date',
      userId: userId,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory DailyUsage.fromFirestore(Map<String, dynamic> data) {
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final updatedAt = data['updatedAt'] != null
        ? (data['updatedAt'] as Timestamp).toDate()
        : DateTime.now();

    return DailyUsage(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      profileViews: data['profileViews'] ?? 0,
      likes: data['likes'] ?? 0,
      passes: data['passes'] ?? 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'date': date,
      'profileViews': profileViews,
      'likes': likes,
      'passes': passes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
