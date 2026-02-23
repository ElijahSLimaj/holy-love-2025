import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _firestore;
  
  static const String _favoritesCollection = 'user_favorites';

  FavoritesService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Add a user to favorites
  Future<void> addToFavorites({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _firestore
          .collection(_favoritesCollection)
          .doc('${currentUserId}_$targetUserId')
          .set({
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a user from favorites
  Future<void> removeFromFavorites({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _firestore
          .collection(_favoritesCollection)
          .doc('${currentUserId}_$targetUserId')
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if a user is favorited
  Future<bool> isFavorited({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final doc = await _firestore
          .collection(_favoritesCollection)
          .doc('${currentUserId}_$targetUserId')
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all favorited user IDs
  Future<Set<String>> getFavoritedUserIds(String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_favoritesCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['targetUserId'] as String)
          .toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Stream of favorited user IDs
  Stream<Set<String>> streamFavoritedUserIds(String currentUserId) {
    return _firestore
        .collection(_favoritesCollection)
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data()['targetUserId'] as String)
          .toSet();
    });
  }
}

