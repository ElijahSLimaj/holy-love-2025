import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats.dart';

class StatsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _statsCollection = 'user_stats';

  final Map<String, UserStats> _statsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  StatsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> initializeUserStats(String userId) async {
    try {
      final statsRef = _firestore.collection(_statsCollection).doc(userId);
      final existingStats = await statsRef.get();

      if (existingStats.exists) {
        return;
      }

      final stats = UserStats.create(userId: userId);
      await statsRef.set(stats.toFirestore());

      _cacheStats(userId, stats);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserStats?> getUserStats(String userId) async {
    if (_isStatsCached(userId)) {
      return _statsCache[userId];
    }

    try {
      final doc = await _firestore.collection(_statsCollection).doc(userId).get();

      if (!doc.exists) {
        await initializeUserStats(userId);
        return UserStats.create(userId: userId);
      }

      final stats = UserStats.fromFirestore(doc.data()!);
      _cacheStats(userId, stats);

      return stats;
    } catch (e) {
      return null;
    }
  }

  Stream<UserStats?> streamUserStats(String userId) {
    return _firestore
        .collection(_statsCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final stats = UserStats.fromFirestore(snapshot.data()!);
      _cacheStats(userId, stats);

      return stats;
    });
  }

  Future<void> incrementLikes(String userId) async {
    try {
      final statsRef = _firestore.collection(_statsCollection).doc(userId);
      final doc = await statsRef.get();
      
      if (!doc.exists) {
        await initializeUserStats(userId);
      }
      
      await statsRef.update({
        'totalLikes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail - stats are not critical
    }
  }

  Future<void> incrementLikesReceived(String userId) async {
    try {
      final statsRef = _firestore.collection(_statsCollection).doc(userId);
      final doc = await statsRef.get();
      
      if (!doc.exists) {
        await initializeUserStats(userId);
      }
      
      await statsRef.update({
        'totalLikesReceived': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail - stats are not critical
    }
  }

  Future<void> incrementMatches(String userId) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'totalMatches': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> incrementProfileViews(String userId) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'profileViews': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> incrementMessagesReceived(String userId) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'messagesReceived': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> incrementMessagesSent(String userId) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'messagesSent': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> updateLastActive(String userId) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePremiumStatus(String userId, bool isPremium) async {
    try {
      await _firestore.collection(_statsCollection).doc(userId).update({
        'isPremium': isPremium,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  bool _isStatsCached(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) return false;

    final isExpired = DateTime.now().difference(timestamp) >= _cacheExpiration;
    return !isExpired;
  }

  void _cacheStats(String userId, UserStats stats) {
    _statsCache[userId] = stats;
    _cacheTimestamps[userId] = DateTime.now();
  }

  void _clearUserCache(String userId) {
    _statsCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  void clearCache() {
    _statsCache.clear();
    _cacheTimestamps.clear();
  }
}
