import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../profile/data/repositories/stats_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../messages/data/repositories/message_repository.dart';

class InteractionService {
  final FirebaseFirestore _firestore;
  final StatsRepository _statsRepository;
  final NotificationRepository _notificationRepository;
  final ProfileRepository _profileRepository;
  final MessageRepository _messageRepository;

  InteractionService({
    FirebaseFirestore? firestore,
    StatsRepository? statsRepository,
    NotificationRepository? notificationRepository,
    ProfileRepository? profileRepository,
    MessageRepository? messageRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _statsRepository = statsRepository ?? StatsRepository(),
        _notificationRepository = notificationRepository ?? NotificationRepository(),
        _profileRepository = profileRepository ?? ProfileRepository(),
        _messageRepository = messageRepository ?? MessageRepository();

  Future<bool> likeUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final batch = _firestore.batch();

      final interactionRef = _firestore
          .collection('user_interactions')
          .doc('${currentUserId}_$targetUserId');

      batch.set(interactionRef, {
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'action': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final reverseInteractionDoc = await _firestore
          .collection('user_interactions')
          .doc('${targetUserId}_$currentUserId')
          .get();

      bool isMatch = false;
      if (reverseInteractionDoc.exists &&
          reverseInteractionDoc.data()?['action'] == 'like') {
        isMatch = true;
        await _createMatch(currentUserId, targetUserId, batch);
      } else {
        await _statsRepository.incrementLikesReceived(targetUserId);

        final currentUserProfile = await _profileRepository.getProfile(currentUserId);
        if (currentUserProfile != null) {
          await _notificationRepository.createLikeNotification(
            userId: targetUserId,
            likerId: currentUserId,
            likerName: '${currentUserProfile.firstName} ${currentUserProfile.lastName}',
            likerPhoto: currentUserProfile.mainPhotoUrl,
          );
        }
      }

      await _statsRepository.incrementLikes(currentUserId);

      await batch.commit();

      debugPrint('User $currentUserId liked $targetUserId. Match: $isMatch');
      return isMatch;

    } catch (e) {
      debugPrint('Error recording like: $e');
      return false;
    }
  }

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

    await _statsRepository.incrementMatches(user1Id);
    await _statsRepository.incrementMatches(user2Id);

    final user1Profile = await _profileRepository.getProfile(user1Id);
    final user2Profile = await _profileRepository.getProfile(user2Id);

    if (user1Profile != null && user2Profile != null) {
      await _notificationRepository.createMatchNotification(
        userId: user1Id,
        matchedUserId: user2Id,
        matchedUserName: '${user2Profile.firstName} ${user2Profile.lastName}',
        matchedUserPhoto: user2Profile.mainPhotoUrl,
      );

      await _notificationRepository.createMatchNotification(
        userId: user2Id,
        matchedUserId: user1Id,
        matchedUserName: '${user1Profile.firstName} ${user1Profile.lastName}',
        matchedUserPhoto: user1Profile.mainPhotoUrl,
      );

      await _messageRepository.createConversation(otherUserId: user2Id);
    }

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
