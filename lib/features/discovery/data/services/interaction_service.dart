import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for handling user interactions (likes, passes, matches)
class InteractionService {
  final FirebaseFirestore _firestore;
  
  InteractionService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Record a like interaction
  Future<bool> likeUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Record the like
      final interactionRef = _firestore
          .collection('user_interactions')
          .doc('${currentUserId}_$targetUserId');
      
      batch.set(interactionRef, {
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'action': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Check if target user has already liked current user (mutual match)
      final reverseInteractionDoc = await _firestore
          .collection('user_interactions')
          .doc('${targetUserId}_$currentUserId')
          .get();
      
      bool isMatch = false;
      if (reverseInteractionDoc.exists && 
          reverseInteractionDoc.data()?['action'] == 'like') {
        // It's a match! Create match record
        isMatch = true;
        await _createMatch(currentUserId, targetUserId, batch);
      }
      
      await batch.commit();
      
      debugPrint('User $currentUserId liked $targetUserId. Match: $isMatch');
      return isMatch;
      
    } catch (e) {
      debugPrint('Error recording like: $e');
      return false;
    }
  }

  /// Record a pass interaction
  Future<void> passUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _firestore
          .collection('user_interactions')
          .doc('${currentUserId}_$targetUserId')
          .set({
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'action': 'pass',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      debugPrint('User $currentUserId passed on $targetUserId');
      
    } catch (e) {
      debugPrint('Error recording pass: $e');
    }
  }

  /// Create a match between two users
  Future<void> _createMatch(
    String user1Id,
    String user2Id,
    WriteBatch batch,
  ) async {
    final matchId = _generateMatchId(user1Id, user2Id);
    
    final matchRef = _firestore.collection('matches').doc(matchId);
    
    batch.set(matchRef, {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'matchId': matchId,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': null,
      'isActive': true,
    });
    
    debugPrint('Created match: $matchId');
  }

  /// Generate consistent match ID for two users
  String _generateMatchId(String user1Id, String user2Id) {
    final sortedIds = [user1Id, user2Id]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Get users that current user has already interacted with
  Future<Set<String>> getInteractedUsers(String currentUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_interactions')
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => doc.data()['targetUserId'] as String)
          .toSet();
          
    } catch (e) {
      debugPrint('Error getting interacted users: $e');
      return <String>{};
    }
  }

  /// Get user's matches
  Future<List<String>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: userId)
          .get();
      
      final querySnapshot2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: userId)
          .get();
      
      final matches = <String>[];
      
      for (final doc in querySnapshot.docs) {
        matches.add(doc.data()['user2Id'] as String);
      }
      
      for (final doc in querySnapshot2.docs) {
        matches.add(doc.data()['user1Id'] as String);
      }
      
      return matches;
      
    } catch (e) {
      debugPrint('Error getting user matches: $e');
      return [];
    }
  }
}
