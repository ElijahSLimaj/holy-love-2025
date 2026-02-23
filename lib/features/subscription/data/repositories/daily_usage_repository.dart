import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/daily_usage.dart';

class DailyUsageRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _collection = 'daily_usage';

  DailyUsage? _cachedUsage;
  String? _cachedDate;

  DailyUsageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  String _todayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  String _docId(String userId) => '${userId}_${_todayString()}';

  Future<DailyUsage> getTodaysUsage(String userId) async {
    final today = _todayString();

    // Return cache if still today
    if (_cachedUsage != null && _cachedDate == today && _cachedUsage!.userId == userId) {
      return _cachedUsage!;
    }

    try {
      final docId = _docId(userId);
      final doc = await _firestore.collection(_collection).doc(docId).get();

      if (doc.exists) {
        final usage = DailyUsage.fromFirestore(doc.data()!);
        _cachedUsage = usage;
        _cachedDate = today;
        return usage;
      }

      // Create new doc for today
      final usage = DailyUsage.create(userId: userId, date: today);
      await _firestore.collection(_collection).doc(docId).set(usage.toFirestore());
      _cachedUsage = usage;
      _cachedDate = today;
      return usage;
    } catch (e) {
      // Return a fresh usage on error (allows actions rather than blocking)
      return DailyUsage.create(userId: userId, date: today);
    }
  }

  Future<DailyUsage> incrementProfileViews(String userId) async {
    return _incrementField(userId, 'profileViews');
  }

  Future<DailyUsage> incrementLikes(String userId) async {
    return _incrementField(userId, 'likes');
  }

  Future<DailyUsage> incrementPasses(String userId) async {
    return _incrementField(userId, 'passes');
  }

  Future<DailyUsage> _incrementField(String userId, String field) async {
    final today = _todayString();
    final docId = _docId(userId);

    try {
      final docRef = _firestore.collection(_collection).doc(docId);
      final doc = await docRef.get();

      if (!doc.exists) {
        // Create the doc first
        final usage = DailyUsage.create(userId: userId, date: today);
        await docRef.set(usage.toFirestore());
      }

      await docRef.update({
        field: FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache so next read fetches fresh data
      _cachedUsage = null;
      _cachedDate = null;

      return getTodaysUsage(userId);
    } catch (e) {
      return getTodaysUsage(userId);
    }
  }

  void clearCache() {
    _cachedUsage = null;
    _cachedDate = null;
  }
}
