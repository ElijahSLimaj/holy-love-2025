import 'dart:async';
// removed unused import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_data.dart';

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
          {...existingData.completedSteps, 'basicInfo': true},
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
        profileCompletionPercentage: 20, // Basic info is 20%
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

  /// Calculate profile completion percentage
  int _calculateCompletionPercentage(Map<String, bool> completedSteps) {
    const stepWeights = {
      'basicInfo': 20,
      'photos': 20,
      'faith': 20,
      'about': 20,
      'preferences': 20,
    };

    int totalPercentage = 0;
    completedSteps.forEach((step, completed) {
      if (completed && stepWeights.containsKey(step)) {
        final weight = stepWeights[step]!;
        totalPercentage += weight;
      } else if (completed) {
      } else {}
    });

    return totalPercentage;
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
