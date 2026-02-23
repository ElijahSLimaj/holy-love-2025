import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  static const String _userInteractionsCollection = 'user_interactions';
  static const String _matchesCollection = 'matches';

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
          .collection(_userInteractionsCollection)
          .doc('${currentUserId}_$targetUserId');

      batch.set(interactionRef, {
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'action': 'like',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final reverseInteractionDoc = await _firestore
          .collection(_userInteractionsCollection)
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

      return isMatch;

    } catch (e) {
      return false;
    }
  }

  Future<void> passUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      await _firestore
          .collection(_userInteractionsCollection)
          .doc('${currentUserId}_$targetUserId')
          .set({
        'userId': currentUserId,
        'targetUserId': targetUserId,
        'action': 'pass',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _createMatch(
    String user1Id,
    String user2Id,
    WriteBatch batch,
  ) async {
    final matchId = _generateMatchId(user1Id, user2Id);

    final matchRef = _firestore.collection(_matchesCollection).doc(matchId);

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
          .collection(_userInteractionsCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();
      
      final likedUsers = <String>{};
      for (var doc in querySnapshot.docs) {
        final action = doc.data()['action'] as String?;
        if (action == 'like') {
          final targetUserId = doc.data()['targetUserId'] as String?;
          if (targetUserId != null) {
            likedUsers.add(targetUserId);
          }
        }
      }
      
      return likedUsers;
          
    } catch (e) {
      return <String>{};
    }
  }

  /// Get user's matches
  Future<List<String>> getUserMatches(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_matchesCollection)
          .where('user1Id', isEqualTo: userId)
          .get();
      
      final querySnapshot2 = await _firestore
          .collection(_matchesCollection)
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
      return [];
    }
  }

  /// Check if current user has already liked a target user
  Future<bool> hasLikedUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      final interactionDoc = await _firestore
          .collection(_userInteractionsCollection)
          .doc('${currentUserId}_$targetUserId')
          .get();
      
      if (!interactionDoc.exists) return false;
      
      final action = interactionDoc.data()?['action'] as String?;
      return action == 'like';
    } catch (e) {
      return false;
    }
  }
}
