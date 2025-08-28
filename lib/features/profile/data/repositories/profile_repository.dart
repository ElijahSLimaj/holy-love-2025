import 'dart:async';
// removed unused import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/profile_data.dart';
import '../../../../core/services/image_upload_service.dart';

/// Repository for managing user profiles with optimized Firestore operations
class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Cache for profile data to minimize reads
  final Map<String, ProfileData> _profileCache = {};
  final Map<String, ProfileDetailsData> _detailsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Firestore collections
  static const String _usersCollection = 'users';
  static const String _profileDetailsCollection = 'profileDetails';

  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create or update basic profile info
  Future<void> saveBasicInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String location,
    GeoPoint? geoLocation,
    String? locationCity,
    String? locationState,
    String? locationCountry,
  }) async {
    final userId = currentUserId;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Calculate birth date from age (approximate)
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));

    // Check if profile exists
    final profileDoc =
        await _firestore.collection(_usersCollection).doc(userId).get();

    if (profileDoc.exists) {}

    final now = DateTime.now();

    if (profileDoc.exists) {
      // Update existing profile
      final existingData = ProfileData.fromFirestore(profileDoc.data()!);

      final updatedData = existingData.copyWith(
        firstName: firstName,
        lastName: lastName,
        age: age,
        birthDate: birthDate,
        location: location,
        geoLocation: geoLocation,
        locationCity: locationCity,
        locationState: locationState,
        locationCountry: locationCountry,
        updatedAt: now,
        completedSteps: {...existingData.completedSteps, 'basicInfo': true},
        profileCompletionPercentage: _calculateCompletionPercentage(
          completedSteps: {...existingData.completedSteps, 'basicInfo': true},
          photoCount: 0, // Will be updated when photos are uploaded
        ),
      );

      await _updateProfile(userId, updatedData);
    } else {
      // Create new profile
      final profileData = ProfileData(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        age: age,
        birthDate: birthDate,
        location: location,
        geoLocation: geoLocation,
        locationCity: locationCity,
        locationState: locationState,
        locationCountry: locationCountry,
        createdAt: now,
        updatedAt: now,
        profileComplete: false,
        profileCompletionPercentage: _calculateCompletionPercentage(
          completedSteps: {'basicInfo': true},
          photoCount: 0,
        ),
        completedSteps: {'basicInfo': true},
        searchName: '${firstName.toLowerCase()} ${lastName.toLowerCase()}',
        searchKeywords:
            ProfileData.generateSearchKeywords(firstName, lastName, location),
        ageGroup: ProfileData.calculateAgeGroup(age),
      );

      await _createProfile(userId, profileData);
    }

    // Clear cache for this user
    _clearUserCache(userId);
  }

  /// Create a new profile with optimized batch write
  Future<void> _createProfile(String userId, ProfileData profileData) async {
    try {
      final batch = _firestore.batch();

      // Main profile document
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileDataMap = profileData.toFirestore();
      batch.set(profileRef, profileDataMap);

      // Initialize profile details subcollection
      final detailsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details');
      final detailsData = ProfileDetailsData(
        interests: [],
        languages: [],
      ).toFirestore();
      batch.set(detailsRef, detailsData);

      // Create search index document for efficient queries
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchIndexData = {
        'userId': userId,
        'searchName': profileData.searchName,
        'age': profileData.age,
        'ageGroup': profileData.ageGroup,
        'location': profileData.location.toLowerCase(),
        'geoLocation': profileData.geoLocation,
        'isActive': true,
        'lastActive': FieldValue.serverTimestamp(),
      };
      batch.set(searchIndexRef, searchIndexData);

      await batch.commit();

      // Clear cache for this user
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update existing profile with minimal writes
  Future<void> _updateProfile(String userId, ProfileData profileData) async {
    try {
      final batch = _firestore.batch();

      // Update main profile
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileDataMap = profileData.toFirestore();
      batch.update(profileRef, profileDataMap);

      // Update search index
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchIndexData = {
        'searchName': profileData.searchName,
        'age': profileData.age,
        'ageGroup': profileData.ageGroup,
        'location': profileData.location.toLowerCase(),
        'geoLocation': profileData.geoLocation,
        'lastActive': FieldValue.serverTimestamp(),
      };
      batch.update(searchIndexRef, searchIndexData);

      await batch.commit();

      // Clear cache for this user
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get profile with caching
  Future<ProfileData?> getProfile(String userId) async {
    // Check cache first
    if (_isProfileCached(userId)) {
      return _profileCache[userId];
    }

    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final profile = ProfileData.fromFirestore(doc.data()!);

      // Cache the profile
      _cacheProfile(userId, profile);

      return profile;
    } catch (e) {
      return null;
    }
  }

  /// Get profile details (extended data)
  Future<ProfileDetailsData?> getProfileDetails(String userId) async {
    // Check cache first
    if (_isDetailsCached(userId)) {
      return _detailsCache[userId];
    }

    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details')
          .get();

      if (!doc.exists) return null;

      final details = ProfileDetailsData.fromFirestore(doc.data()!);

      // Cache the details
      _cacheDetails(userId, details);

      return details;
    } catch (e) {
      return null;
    }
  }

  /// Stream profile changes with caching
  Stream<ProfileData?> streamProfile(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;

      final profile = ProfileData.fromFirestore(snapshot.data()!);
      _cacheProfile(userId, profile);

      return profile;
    });
  }

  /// Batch update for multiple profile fields
  Future<void> batchUpdateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(_usersCollection).doc(userId).update(updates);

      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }



  /// Cache management methods
  bool _isProfileCached(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) {
      return false;
    }

    final isExpired = DateTime.now().difference(timestamp) >= _cacheExpiration;

    return !isExpired;
  }

  bool _isDetailsCached(String userId) {
    final key = '${userId}_details';
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      return false;
    }

    final isExpired = DateTime.now().difference(timestamp) >= _cacheExpiration;

    return !isExpired;
  }

  void _cacheProfile(String userId, ProfileData profile) {
    _profileCache[userId] = profile;
    _cacheTimestamps[userId] = DateTime.now();
  }

  void _cacheDetails(String userId, ProfileDetailsData details) {
    _detailsCache[userId] = details;
    _cacheTimestamps['${userId}_details'] = DateTime.now();
  }

  void _clearUserCache(String userId) {
    _profileCache.remove(userId);
    _detailsCache.remove(userId);
    _cacheTimestamps.remove(userId);
    _cacheTimestamps.remove('${userId}_details');
  }

  /// Clear all cached data
  void clearCache() {
    _profileCache.clear();
    _detailsCache.clear();
    _cacheTimestamps.clear();
  }

  /// Validate profile data before saving
  ValidationResult validateBasicInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String location,
  }) {
    final errors = <String, String>{};

    if (firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    } else if (firstName.length < 2) {
      errors['firstName'] = 'First name must be at least 2 characters';
    } else {}

    if (lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    } else if (lastName.length < 2) {
      errors['lastName'] = 'Last name must be at least 2 characters';
    } else {}

    if (age < 18) {
      errors['age'] = 'You must be at least 18 years old';
    } else if (age > 100) {
      errors['age'] = 'Please enter a valid age';
    } else {}

    if (location.trim().isEmpty) {
      errors['location'] = 'Location is required';
    } else {}

    final isValid = errors.isEmpty;
    if (!isValid) {}

    return ValidationResult(
      isValid: isValid,
      errors: errors,
    );
  }

  /// Save photo URLs to user profile
  Future<void> savePhotos({
    required String userId,
    required List<String> photoUrls,
    required List<String> thumbnailUrls,
    String? mainPhotoUrl,
    String? mainThumbnailUrl,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current profile to calculate completion
      final profileDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final currentData = profileDoc.data() ?? {};
      final currentSteps = Map<String, bool>.from(currentData['completedSteps'] ?? {});
      currentSteps['photos'] = true;
      
      final newCompletionPercentage = _calculateCompletionPercentage(
        completedSteps: currentSteps,
        photoCount: photoUrls.length,
      );

      // Update main profile with main photo URLs
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileUpdates = {
        'mainPhotoUrl': mainPhotoUrl,
        'mainPhotoThumbnailUrl': mainThumbnailUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'completedSteps.photos': true,
        'profileCompletionPercentage': newCompletionPercentage,
      };
      batch.update(profileRef, profileUpdates);

      // Save all photo URLs to profile details
      final detailsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details');
      
      final detailsUpdates = {
        'photoUrls': photoUrls,
        'thumbnailUrls': thumbnailUrls,
        'photoCount': photoUrls.length,
        'lastPhotoUpdate': FieldValue.serverTimestamp(),
      };
      batch.update(detailsRef, detailsUpdates);

      // Update search index with main photo
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchUpdates = {
        'mainPhotoUrl': mainPhotoUrl,
        'hasPhotos': photoUrls.isNotEmpty,
        'photoCount': photoUrls.length,
      };
      batch.update(searchIndexRef, searchUpdates);

      await batch.commit();

      // Clear cache
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Save faith information to profile details
  Future<void> saveFaithInfo({
    required String userId,
    String? denomination,
    String? churchAttendance,
    String? favoriteBibleVerse,
    String? faithStory,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current profile to calculate completion
      final profileDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final currentData = profileDoc.data() ?? {};
      final currentSteps = Map<String, bool>.from(currentData['completedSteps'] ?? {});
      currentSteps['faith'] = true;
      
      // Get current photo count for completion calculation
      final detailsDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details')
          .get();
      final photoCount = detailsDoc.data()?['photoCount'] ?? 0;
      
      final newCompletionPercentage = _calculateCompletionPercentage(
        completedSteps: currentSteps,
        photoCount: photoCount,
      );

      // Update main profile completion status
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileUpdates = {
        'updatedAt': FieldValue.serverTimestamp(),
        'completedSteps.faith': true,
        'profileCompletionPercentage': newCompletionPercentage,
      };
      batch.update(profileRef, profileUpdates);

      // Save faith info to profile details
      final detailsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details');
      
      final detailsUpdates = {
        'denomination': denomination,
        'churchAttendance': churchAttendance,
        'favoriteBibleVerse': favoriteBibleVerse,
        'faithStory': faithStory,
        'lastFaithUpdate': FieldValue.serverTimestamp(),
      };
      batch.update(detailsRef, detailsUpdates);

      // Update search index with faith info for matching
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchUpdates = {
        'denomination': denomination,
        'churchAttendance': churchAttendance,
        'hasFaithInfo': denomination != null || churchAttendance != null,
      };
      batch.update(searchIndexRef, searchUpdates);

      await batch.commit();

      // Clear cache
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Save about information to profile details
  Future<void> saveAboutInfo({
    required String userId,
    String? bio,
    required List<String> interests,
    String? relationshipGoal,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current profile to calculate completion
      final profileDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final currentData = profileDoc.data() ?? {};
      final currentSteps = Map<String, bool>.from(currentData['completedSteps'] ?? {});
      currentSteps['about'] = true;
      
      // Get current photo count for completion calculation
      final detailsDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details')
          .get();
      final photoCount = detailsDoc.data()?['photoCount'] ?? 0;
      
      final newCompletionPercentage = _calculateCompletionPercentage(
        completedSteps: currentSteps,
        photoCount: photoCount,
      );

      // Update main profile completion status
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileUpdates = {
        'updatedAt': FieldValue.serverTimestamp(),
        'completedSteps.about': true,
        'profileCompletionPercentage': newCompletionPercentage,
      };
      batch.update(profileRef, profileUpdates);

      // Save about info to profile details
      final detailsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details');
      
      final detailsUpdates = {
        'bio': bio,
        'interests': interests,
        'relationshipGoal': relationshipGoal,
        'lastAboutUpdate': FieldValue.serverTimestamp(),
      };
      batch.update(detailsRef, detailsUpdates);

      // Update search index with about info for matching
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchUpdates = {
        'interests': interests,
        'relationshipGoal': relationshipGoal,
        'hasAboutInfo': bio != null && bio.isNotEmpty,
        'interestCount': interests.length,
      };
      batch.update(searchIndexRef, searchUpdates);

      await batch.commit();

      // Clear cache
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Save preferences information to profile details
  Future<void> savePreferencesInfo({
    required String userId,
    required int ageRangeMin,
    required int ageRangeMax,
    required int maxDistance,
    String? faithImportance,
    required List<String> dealBreakers,
  }) async {
    try {
      final batch = _firestore.batch();

      // Get current profile to calculate completion
      final profileDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      final currentData = profileDoc.data() ?? {};
      final currentSteps = Map<String, bool>.from(currentData['completedSteps'] ?? {});
      currentSteps['preferences'] = true;
      
      // Get current photo count for completion calculation
      final detailsDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details')
          .get();
      final photoCount = detailsDoc.data()?['photoCount'] ?? 0;
      
      final newCompletionPercentage = _calculateCompletionPercentage(
        completedSteps: currentSteps,
        photoCount: photoCount,
      );

      // Update main profile completion status
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileUpdates = {
        'updatedAt': FieldValue.serverTimestamp(),
        'completedSteps.preferences': true,
        'profileComplete': newCompletionPercentage >= 90, // Consider complete at 90%+
        'profileCompletionPercentage': newCompletionPercentage,
      };
      batch.update(profileRef, profileUpdates);

      // Save preferences to profile details
      final detailsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details');
      
      final preferencesData = {
        'ageRangeMin': ageRangeMin,
        'ageRangeMax': ageRangeMax,
        'maxDistance': maxDistance,
        'faithImportance': faithImportance,
        'dealBreakers': dealBreakers,
      };
      
      final detailsUpdates = {
        'preferences': preferencesData,
        'lastPreferencesUpdate': FieldValue.serverTimestamp(),
      };
      batch.update(detailsRef, detailsUpdates);

      // Update search index with preferences for matching
      final searchIndexRef = _firestore.collection('searchIndex').doc(userId);
      final searchUpdates = {
        'ageRangeMin': ageRangeMin,
        'ageRangeMax': ageRangeMax,
        'maxDistance': maxDistance,
        'faithImportance': faithImportance,
        'dealBreakers': dealBreakers,
        'profileComplete': true,
      };
      batch.update(searchIndexRef, searchUpdates);

      await batch.commit();

      // Clear cache
      _clearUserCache(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Calculate profile completion percentage based on completed steps and photo count
  int _calculateCompletionPercentage({
    required Map<String, bool> completedSteps,
    int photoCount = 0,
  }) {
    int percentage = 0;
    
    // Basic Info: 20% (required)
    if (completedSteps['basicInfo'] == true) {
      percentage += 20;
    }
    
    // Photos: 20% base + 10% bonus for 6 photos (30% max)
    if (completedSteps['photos'] == true) {
      percentage += 20; // Base for having any photos
      if (photoCount >= 6) {
        percentage += 10; // Bonus for having all 6 photos
      }
    }
    
    // Faith: 20% (required)
    if (completedSteps['faith'] == true) {
      percentage += 20;
    }
    
    // About: 20% (required)  
    if (completedSteps['about'] == true) {
      percentage += 20;
    }
    
    // Preferences: 10% (required)
    if (completedSteps['preferences'] == true) {
      percentage += 10;
    }
    
    return percentage.clamp(0, 100);
  }

  /// Recalculate and update profile completion percentage for existing user
  Future<void> recalculateCompletion(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // Get current profile data
      final profileDoc = await _firestore.collection(_usersCollection).doc(userId).get();
      if (!profileDoc.exists) return;
      
      final currentData = profileDoc.data()!;
      final currentSteps = Map<String, bool>.from(currentData['completedSteps'] ?? {});
      
      // Get photo count
      final detailsDoc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_profileDetailsCollection)
          .doc('details')
          .get();
      final photoCount = detailsDoc.data()?['photoCount'] ?? 0;
      
      final newCompletionPercentage = _calculateCompletionPercentage(
        completedSteps: currentSteps,
        photoCount: photoCount,
      );
      
      // Update profile with recalculated percentage
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final updates = {
        'profileCompletionPercentage': newCompletionPercentage,
        'profileComplete': newCompletionPercentage >= 90,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      batch.update(profileRef, updates);
      
      await batch.commit();
      _clearUserCache(userId);
    } catch (e) {
      debugPrint('Error recalculating completion: $e');
    }
  }

  /// Delete a photo from user's profile
  Future<void> deletePhoto({
    required String userId,
    required String photoUrl,
    required int photoIndex,
  }) async {
    try {
      // Delete from Firebase Storage
      await ImageUploadService.deleteImage(photoUrl);

      // Get current profile data
      final profile = await getProfile(userId);
      final details = await getProfileDetails(userId);
      
      if (profile == null || details == null) return;

      // Update photo arrays
      final photoUrls = List<String>.from(details.photoUrls ?? []);
      final thumbnailUrls = List<String>.from(details.thumbnailUrls ?? []);
      
      if (photoIndex < photoUrls.length) {
        photoUrls.removeAt(photoIndex);
      }
      if (photoIndex < thumbnailUrls.length) {
        thumbnailUrls.removeAt(photoIndex);
      }

      // Determine new main photo
      String? newMainPhoto;
      String? newMainThumbnail;
      if (photoUrls.isNotEmpty) {
        newMainPhoto = photoUrls.first;
        newMainThumbnail = thumbnailUrls.isNotEmpty ? thumbnailUrls.first : null;
      }

      // Save updated photo arrays
      await savePhotos(
        userId: userId,
        photoUrls: photoUrls,
        thumbnailUrls: thumbnailUrls,
        mainPhotoUrl: newMainPhoto,
        mainThumbnailUrl: newMainThumbnail,
      );
    } catch (e) {
      rethrow;
    }
  }
}

/// Result of validation
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
