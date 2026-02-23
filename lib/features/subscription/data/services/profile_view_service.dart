import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileViewData {
  final String viewerId;
  final String viewedUserId;
  final String date;
  final DateTime timestamp;

  ProfileViewData({
    required this.viewerId,
    required this.viewedUserId,
    required this.date,
    required this.timestamp,
  });

  factory ProfileViewData.fromFirestore(Map<String, dynamic> data) {
    return ProfileViewData(
      viewerId: data['viewerId'] ?? '',
      viewedUserId: data['viewedUserId'] ?? '',
      date: data['date'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class ProfileViewService {
  final FirebaseFirestore _firestore;

  static const String _collection = 'profile_views';

  ProfileViewService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> recordView({
    required String viewerId,
    required String viewedUserId,
  }) async {
    try {
      final docId = '${viewedUserId}_${viewerId}_${_todayString()}';
      await _firestore.collection(_collection).doc(docId).set({
        'viewerId': viewerId,
        'viewedUserId': viewedUserId,
        'date': _todayString(),
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail — profile view tracking is not critical
    }
  }

  Future<List<ProfileViewData>> getViewers(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('viewedUserId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProfileViewData.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> getViewerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('viewedUserId', isEqualTo: userId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
