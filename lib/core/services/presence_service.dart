import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum PresenceStatus {
  online,
  away,
  offline,
}

class PresenceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _presenceCollection = 'user_presence';
  static const Duration _onlineThreshold = Duration(minutes: 5);

  PresenceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> setOnline() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection(_presenceCollection).doc(userId).set({
        'userId': userId,
        'status': PresenceStatus.online.name,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> setAway() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection(_presenceCollection).doc(userId).set({
        'userId': userId,
        'status': PresenceStatus.away.name,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> setOffline() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection(_presenceCollection).doc(userId).set({
        'userId': userId,
        'status': PresenceStatus.offline.name,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail
    }
  }

  Future<PresenceStatus> getUserStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection(_presenceCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return PresenceStatus.offline;

      final data = doc.data()!;
      final statusString = data['status'] as String?;
      final lastSeen = data['lastSeen'] as Timestamp?;

      if (statusString == null || lastSeen == null) {
        return PresenceStatus.offline;
      }

      final lastSeenDate = lastSeen.toDate();
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      if (difference > _onlineThreshold) {
        return PresenceStatus.offline;
      }

      return PresenceStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => PresenceStatus.offline,
      );
    } catch (e) {
      return PresenceStatus.offline;
    }
  }

  Stream<PresenceStatus> streamUserStatus(String userId) {
    return _firestore
        .collection(_presenceCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return PresenceStatus.offline;

      final data = snapshot.data()!;
      final statusString = data['status'] as String?;
      final lastSeen = data['lastSeen'] as Timestamp?;

      if (statusString == null || lastSeen == null) {
        return PresenceStatus.offline;
      }

      final lastSeenDate = lastSeen.toDate();
      final now = DateTime.now();
      final difference = now.difference(lastSeenDate);

      if (difference > _onlineThreshold) {
        return PresenceStatus.offline;
      }

      return PresenceStatus.values.firstWhere(
        (e) => e.name == statusString,
        orElse: () => PresenceStatus.offline,
      );
    });
  }

  Future<DateTime?> getLastSeen(String userId) async {
    try {
      final doc = await _firestore
          .collection(_presenceCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final lastSeen = doc.data()?['lastSeen'] as Timestamp?;
      return lastSeen?.toDate();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateHeartbeat() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _firestore.collection(_presenceCollection).doc(userId).set({
        'userId': userId,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - presence is not critical
    }
  }

  void startHeartbeat() {
    Stream.periodic(const Duration(minutes: 2)).listen((_) {
      updateHeartbeat();
    });
  }
}
