import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../profile/data/models/profile_data.dart';
import '../models/user_profile.dart';
import '../models/match_score.dart';
import '../../../../core/services/geo_service.dart';

/// Service for finding and ranking potential matches
class MatchingService {
  final FirebaseFirestore _firestore;
  
  MatchingService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Find potential matches for a user
  Future<List<UserProfile>> findMatches({
    required String currentUserId,
    int limit = 20,
  }) async {
    try {
      debugPrint('Finding matches for user: $currentUserId');
      
      // Get current user's profile and preferences
      final currentUserProfile = await _getCurrentUserProfile(currentUserId);
      if (currentUserProfile == null) {
        debugPrint('Current user profile not found');
        return [];
      }
      
      // Get potential candidates
      final candidates = await _getCandidates(
        currentUserId: currentUserId,
        userProfile: currentUserProfile,
        limit: limit * 2, // Get more candidates to filter and rank
      );
      
      debugPrint('Found ${candidates.length} candidates');
      
      // Calculate compatibility scores and rank
      final rankedMatches = await _rankCandidates(
        currentUserProfile: currentUserProfile,
        candidates: candidates,
      );
      
      debugPrint('Found ${rankedMatches.length} real matches');
      
      // Return only real matches - no mock data fallback
      return rankedMatches.take(limit).toList();
      
    } catch (e) {
      debugPrint('Error finding matches: $e');
      return [];
    }
  }

  /// Get current user's profile data
  Future<ProfileData?> _getCurrentUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      return ProfileData.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('Error getting current user profile: $e');
      return null;
    }
  }

  /// Get potential candidates with basic filtering
  Future<List<UserProfile>> _getCandidates({
    required String currentUserId,
    required ProfileData userProfile,
    required int limit,
  }) async {
    try {
      // Get user's preferences
      final preferencesDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('profile_details')
          .doc('details')
          .get();
      
      final preferences = preferencesDoc.data()?['preferences'] as Map<String, dynamic>?;
      
      // Query potential matches with basic filters
      Query query = _firestore
          .collection('users')
          .where('profileComplete', isEqualTo: true)
          .limit(limit);

      // Exclude current user
      // Note: Firestore doesn't support != so we'll filter this client-side
      
      final querySnapshot = await query.get();
      final candidates = <UserProfile>[];
      
      for (final doc in querySnapshot.docs) {
        if (doc.id == currentUserId) continue; // Skip current user
        
        try {
          final profileData = ProfileData.fromFirestore(doc.data() as Map<String, dynamic>);
          
          // Get profile details
          final detailsDoc = await _firestore
              .collection('users')
              .doc(doc.id)
              .collection('profile_details')
              .doc('details')
              .get();
          
          final profileDetails = detailsDoc.exists 
              ? ProfileDetailsData.fromFirestore(detailsDoc.data()!)
              : null;
          
          // Apply basic filters
          if (_passesBasicFilters(
            candidate: profileData,
            candidateDetails: profileDetails,
            currentUser: userProfile,
            preferences: preferences,
          )) {
            // Convert to UserProfile for compatibility
            final candidateUserProfile = _convertToUserProfile(profileData, profileDetails, userProfile);
            candidates.add(candidateUserProfile);
          }
        } catch (e) {
          debugPrint('Error processing candidate ${doc.id}: $e');
        }
      }
      
      return candidates;
    } catch (e) {
      debugPrint('Error getting candidates: $e');
      return [];
    }
  }

  /// Apply basic filters (age, distance, deal breakers)
  bool _passesBasicFilters({
    required ProfileData candidate,
    ProfileDetailsData? candidateDetails,
    required ProfileData currentUser,
    Map<String, dynamic>? preferences,
  }) {
    if (preferences == null) return true;
    
    // Age filter
    final ageRangeMin = preferences['ageRangeMin'] as int?;
    final ageRangeMax = preferences['ageRangeMax'] as int?;
    
    if (ageRangeMin != null && candidate.age < ageRangeMin) return false;
    if (ageRangeMax != null && candidate.age > ageRangeMax) return false;
    
    // Distance filter (simplified - in a real app you'd calculate actual distance)
    final maxDistance = preferences['maxDistance'] as int?;
    if (maxDistance != null && maxDistance < 100) {
      // For now, accept all users within max distance
      // TODO: Implement actual geo-distance calculation
    }
    
    // Deal breakers filter
    final dealBreakers = preferences['dealBreakers'] as List<dynamic>?;
    if (dealBreakers != null && dealBreakers.isNotEmpty) {
      // Check against candidate's profile
      if (dealBreakers.contains('smoking') && (candidateDetails?.smokes == true)) return false;
      if (dealBreakers.contains('drinking') && (candidateDetails?.drinks == true)) return false;
      if (dealBreakers.contains('different_faith') && 
          candidate.completedSteps['faith'] == true &&
          candidateDetails?.denomination != null &&
          candidateDetails?.denomination != _getCurrentUserDenomination(currentUser.userId)) {
        return false;
      }
      // TODO: Add more deal breaker checks
    }
    
    return true;
  }

  /// Get current user's denomination (simplified)
  String? _getCurrentUserDenomination(String userId) {
    // TODO: Cache this or pass it in
    return null;
  }

  /// Rank candidates by compatibility score
  Future<List<UserProfile>> _rankCandidates({
    required ProfileData currentUserProfile,
    required List<UserProfile> candidates,
  }) async {
    final scoredCandidates = <MapEntry<UserProfile, MatchScore>>[];
    
    for (final candidate in candidates) {
      final score = await _calculateCompatibilityScore(
        currentUser: currentUserProfile,
        candidate: candidate,
      );
      scoredCandidates.add(MapEntry(candidate, score));
    }
    
    // Sort by total score (descending)
    scoredCandidates.sort((a, b) => b.value.totalScore.compareTo(a.value.totalScore));
    
    // Return sorted candidates
    return scoredCandidates.map((entry) => entry.key).toList();
  }

  /// Calculate compatibility score between two users
  Future<MatchScore> _calculateCompatibilityScore({
    required ProfileData currentUser,
    required UserProfile candidate,
  }) async {
    int faithScore = 0;
    int locationScore = 0;
    int interestsScore = 0;
    int ageScore = 0;
    
    // Faith compatibility (40 points max)
    faithScore = _calculateFaithCompatibility(currentUser, candidate);
    
    // Location proximity (25 points max)
    locationScore = _calculateLocationScore(currentUser, candidate);
    
    // Shared interests (20 points max)
    interestsScore = _calculateInterestsScore(currentUser, candidate);
    
    // Age compatibility (15 points max)
    ageScore = _calculateAgeCompatibility(currentUser, candidate);
    
    final totalScore = faithScore + locationScore + interestsScore + ageScore;
    
    return MatchScore(
      faithCompatibility: faithScore,
      locationProximity: locationScore,
      sharedInterests: interestsScore,
      ageCompatibility: ageScore,
      totalScore: totalScore,
      reasons: _generateMatchReasons(
        faithScore: faithScore,
        locationScore: locationScore,
        interestsScore: interestsScore,
        ageScore: ageScore,
        candidate: candidate,
      ),
    );
  }

  /// Calculate faith compatibility score
  int _calculateFaithCompatibility(ProfileData currentUser, UserProfile candidate) {
    // For now, use denomination matching
    // TODO: Get actual faith data from profile details
    
    if (candidate.denomination.isEmpty) return 0;
    
    // Same denomination = high compatibility
    if (candidate.denomination.toLowerCase().contains('non-denominational') ||
        candidate.denomination.toLowerCase().contains('christian')) {
      return 25; // Base Christian faith compatibility
    }
    
    // TODO: Implement actual denomination matching logic
    return 15; // Default faith compatibility
  }

  /// Calculate location proximity score using real geo-distance
  int _calculateLocationScore(ProfileData currentUser, UserProfile candidate) {
    // Use real geo-distance calculation if coordinates are available
    if (currentUser.geoLocation != null && candidate.latitude != null && candidate.longitude != null) {
      final distance = GeoService.calculateDistance(
        lat1: currentUser.geoLocation!.latitude,
        lng1: currentUser.geoLocation!.longitude,
        lat2: candidate.latitude!,
        lng2: candidate.longitude!,
      );
      
      debugPrint('Real distance calculated: ${distance.toStringAsFixed(1)} km between ${currentUser.firstName} and ${candidate.firstName}');
      
      // Score based on actual distance
      if (distance <= 5) return 25;   // Very close
      if (distance <= 15) return 20;  // Close
      if (distance <= 30) return 15;  // Moderate
      if (distance <= 50) return 10;  // Far
      if (distance <= 100) return 5;  // Very far
      
      return 0; // Too far
    }
    
    // Fallback to mock distance if coordinates unavailable
    final distance = candidate.distanceKm;
    debugPrint('Using fallback distance: $distance km for ${candidate.firstName}');
    
    if (distance <= 10) return 25;
    if (distance <= 25) return 15;
    if (distance <= 50) return 5;
    
    return 0;
  }

  /// Calculate shared interests score
  int _calculateInterestsScore(ProfileData currentUser, UserProfile candidate) {
    // TODO: Get actual interests from profile details
    final candidateInterests = candidate.interests;
    
    if (candidateInterests.isEmpty) return 0;
    
    // For now, give points based on number of interests (proxy for compatibility)
    if (candidateInterests.length >= 5) return 20;
    if (candidateInterests.length >= 3) return 15;
    if (candidateInterests.isNotEmpty) return 10;
    
    return 0;
  }

  /// Calculate age compatibility score
  int _calculateAgeCompatibility(ProfileData currentUser, UserProfile candidate) {
    final ageDifference = (currentUser.age - candidate.age).abs();
    
    if (ageDifference <= 2) return 15;
    if (ageDifference <= 5) return 10;
    if (ageDifference <= 8) return 5;
    
    return 0;
  }

  /// Generate human-readable match reasons
  List<String> _generateMatchReasons({
    required int faithScore,
    required int locationScore,
    required int interestsScore,
    required int ageScore,
    required UserProfile candidate,
  }) {
    final reasons = <String>[];
    
    if (faithScore >= 20) {
      reasons.add('Strong faith compatibility');
    } else if (faithScore >= 10) {
      reasons.add('Shared Christian values');
    }
    
    if (locationScore >= 20) {
      reasons.add('Very close location');
    } else if (locationScore >= 10) {
      reasons.add('Nearby location');
    }
    
    if (interestsScore >= 15) {
      reasons.add('Many shared interests');
    } else if (interestsScore >= 10) {
      reasons.add('Some shared interests');
    }
    
    if (ageScore >= 10) {
      reasons.add('Similar age');
    }
    
    if (reasons.isEmpty) {
      reasons.add('Potential compatibility');
    }
    
    return reasons;
  }

  /// Convert ProfileData + ProfileDetailsData to UserProfile
  UserProfile _convertToUserProfile(ProfileData profile, ProfileDetailsData? details, [ProfileData? currentUser]) {
    // Calculate real distance if both users have coordinates
    double distanceKm = _calculateRandomDistance().toDouble(); // Fallback
    
    if (currentUser?.geoLocation != null && profile.geoLocation != null) {
      distanceKm = GeoService.calculateDistance(
        lat1: currentUser!.geoLocation!.latitude,
        lng1: currentUser.geoLocation!.longitude,
        lat2: profile.geoLocation!.latitude,
        lng2: profile.geoLocation!.longitude,
      );
    }
    
    return UserProfile(
      id: profile.userId,
      firstName: profile.firstName,
      lastName: profile.lastName,
      age: profile.age,
      location: profile.location,
      latitude: profile.geoLocation?.latitude,
      longitude: profile.geoLocation?.longitude,
      photoUrls: [
        if (profile.mainPhotoUrl != null) profile.mainPhotoUrl!,
        ...(details?.photoUrls ?? []),
      ],
      bio: details?.bio ?? '',
      denomination: details?.denomination ?? '',
      churchAttendance: details?.churchAttendance ?? '',
      favoriteVerse: details?.favoriteBibleVerse ?? '',
      faithStory: details?.faithStory ?? '',
      interests: details?.interests ?? [],
      relationshipGoal: details?.relationshipGoal ?? '',
      distanceKm: distanceKm.round(),
      isOnline: Random().nextBool(), // TODO: Implement real online status
      lastSeen: DateTime.now().subtract(Duration(minutes: Random().nextInt(1440))),
      occupation: details?.occupation ?? '',
      education: details?.education ?? '',
      languages: details?.languages ?? ['English'],
      height: details?.height ?? '',
      hasChildren: details?.hasChildren ?? false,
      wantsChildren: details?.wantsChildren ?? false,
      drinks: details?.drinks ?? false,
      smokes: details?.smokes ?? false,
      personalityType: details?.personalityType ?? '',
    );
  }

  /// Calculate random distance for now (TODO: implement real geo-distance)
  int _calculateRandomDistance() {
    return Random().nextInt(50) + 1; // 1-50 km
  }
}
