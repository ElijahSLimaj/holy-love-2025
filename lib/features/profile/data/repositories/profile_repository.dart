import 'dart:async';
import 'package:flutter/foundation.dart';
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
    debugPrint('🔄 [ProfileRepository] saveBasicInfo started');
    debugPrint('📝 [ProfileRepository] Input data: firstName=$firstName, lastName=$lastName, age=$age, location=$location');
    
    final userId = currentUserId;
    debugPrint('👤 [ProfileRepository] Current user ID: $userId');
    
    if (userId == null) {
      debugPrint('❌ [ProfileRepository] User not authenticated - throwing exception');
      throw Exception('User not authenticated');
    }

    // Calculate birth date from age (approximate)
    final birthDate = DateTime.now().subtract(Duration(days: age * 365));
    debugPrint('📅 [ProfileRepository] Calculated birth date: $birthDate');

    // Check if profile exists
    debugPrint('🔍 [ProfileRepository] Checking if profile exists for user: $userId');
    final profileDoc = await _firestore
        .collection(_usersCollection)
        .doc(userId)
        .get();

    debugPrint('📄 [ProfileRepository] Profile document exists: ${profileDoc.exists}');
    if (profileDoc.exists) {
      debugPrint('📄 [ProfileRepository] Profile document data: ${profileDoc.data()}');
    }

    final now = DateTime.now();
    
    if (profileDoc.exists) {
      debugPrint('🔄 [ProfileRepository] Updating existing profile');
      // Update existing profile
      final existingData = ProfileData.fromFirestore(profileDoc.data()!);
      debugPrint('📄 [ProfileRepository] Existing profile data: ${existingData.toFirestore()}');
      
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

      debugPrint('📝 [ProfileRepository] Updated profile data: ${updatedData.toFirestore()}');
      await _updateProfile(userId, updatedData);
    } else {
      debugPrint('🆕 [ProfileRepository] Creating new profile');
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
        searchKeywords: ProfileData.generateSearchKeywords(firstName, lastName, location),
        ageGroup: ProfileData.calculateAgeGroup(age),
      );

      debugPrint('📝 [ProfileRepository] New profile data: ${profileData.toFirestore()}');
      await _createProfile(userId, profileData);
    }

    // Clear cache for this user
    _clearUserCache(userId);
  }

  /// Create a new profile with optimized batch write
  Future<void> _createProfile(String userId, ProfileData profileData) async {
    debugPrint('🔄 [ProfileRepository] _createProfile started for user: $userId');
    
    try {
      final batch = _firestore.batch();
      debugPrint('📦 [ProfileRepository] Created Firestore batch');
      
      // Main profile document
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileDataMap = profileData.toFirestore();
      batch.set(profileRef, profileDataMap);
      debugPrint('📝 [ProfileRepository] Added main profile document to batch: $profileDataMap');
      
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
      debugPrint('📝 [ProfileRepository] Added profile details to batch: $detailsData');
      
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
      debugPrint('📝 [ProfileRepository] Added search index to batch: $searchIndexData');
      
      debugPrint('🚀 [ProfileRepository] Committing batch...');
      await batch.commit();
      debugPrint('✅ [ProfileRepository] Batch committed successfully');
      
      // Clear cache for this user
      _clearUserCache(userId);
      debugPrint('🗑️ [ProfileRepository] Cleared cache for user: $userId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileRepository] Error in _createProfile: $e');
      debugPrint('📚 [ProfileRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update existing profile with minimal writes
  Future<void> _updateProfile(String userId, ProfileData profileData) async {
    debugPrint('🔄 [ProfileRepository] _updateProfile started for user: $userId');
    
    try {
      final batch = _firestore.batch();
      debugPrint('📦 [ProfileRepository] Created Firestore batch for update');
      
      // Update main profile
      final profileRef = _firestore.collection(_usersCollection).doc(userId);
      final profileDataMap = profileData.toFirestore();
      batch.update(profileRef, profileDataMap);
      debugPrint('📝 [ProfileRepository] Added profile update to batch: $profileDataMap');
      
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
      debugPrint('📝 [ProfileRepository] Added search index update to batch: $searchIndexData');
      
      debugPrint('🚀 [ProfileRepository] Committing update batch...');
      await batch.commit();
      debugPrint('✅ [ProfileRepository] Update batch committed successfully');
      
      // Clear cache for this user
      _clearUserCache(userId);
      debugPrint('🗑️ [ProfileRepository] Cleared cache for user: $userId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileRepository] Error in _updateProfile: $e');
      debugPrint('📚 [ProfileRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get profile with caching
  Future<ProfileData?> getProfile(String userId) async {
    debugPrint('🔄 [ProfileRepository] getProfile started for user: $userId');
    
    // Check cache first
    if (_isProfileCached(userId)) {
      debugPrint('💾 [ProfileRepository] Returning cached profile for user: $userId');
      return _profileCache[userId];
    }

    debugPrint('🌐 [ProfileRepository] Cache miss, fetching from Firestore...');
    
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      debugPrint('📄 [ProfileRepository] Firestore document exists: ${doc.exists}');
      
      if (!doc.exists) {
        debugPrint('❌ [ProfileRepository] Profile document does not exist for user: $userId');
        return null;
      }

      debugPrint('📄 [ProfileRepository] Firestore document data: ${doc.data()}');
      
      final profile = ProfileData.fromFirestore(doc.data()!);
      debugPrint('📝 [ProfileRepository] Parsed profile data: ${profile.toFirestore()}');
      
      // Cache the profile
      _cacheProfile(userId, profile);
      debugPrint('💾 [ProfileRepository] Cached profile for user: $userId');
      
      return profile;
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileRepository] Error fetching profile: $e');
      debugPrint('📚 [ProfileRepository] Stack trace: $stackTrace');
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
      debugPrint('Error fetching profile details: $e');
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
    debugPrint('🔄 [ProfileRepository] batchUpdateProfile started for user: $userId');
    debugPrint('📝 [ProfileRepository] Updates to apply: $updates');
    
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      debugPrint('⏰ [ProfileRepository] Added updatedAt timestamp');
      
      debugPrint('🚀 [ProfileRepository] Updating Firestore document...');
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updates);
      
      debugPrint('✅ [ProfileRepository] Firestore document updated successfully');
      
      _clearUserCache(userId);
      debugPrint('🗑️ [ProfileRepository] Cleared cache for user: $userId');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileRepository] Error in batchUpdateProfile: $e');
      debugPrint('📚 [ProfileRepository] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Calculate profile completion percentage
  int _calculateCompletionPercentage(Map<String, bool> completedSteps) {
    debugPrint('🔄 [ProfileRepository] _calculateCompletionPercentage started');
    debugPrint('📝 [ProfileRepository] Completed steps: $completedSteps');
    
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
        debugPrint('✅ [ProfileRepository] Step "$step" completed, added $weight% (total: $totalPercentage%)');
      } else if (completed) {
        debugPrint('⚠️ [ProfileRepository] Step "$step" completed but no weight defined');
      } else {
        debugPrint('❌ [ProfileRepository] Step "$step" not completed');
      }
    });
    
    debugPrint('📊 [ProfileRepository] Final completion percentage: $totalPercentage%');
    return totalPercentage;
  }

  /// Cache management methods
  bool _isProfileCached(String userId) {
    final timestamp = _cacheTimestamps[userId];
    if (timestamp == null) {
      debugPrint('💾 [ProfileRepository] No cache timestamp found for user: $userId');
      return false;
    }
    
    final isExpired = DateTime.now().difference(timestamp) >= _cacheExpiration;
    debugPrint('💾 [ProfileRepository] Cache for user $userId: ${isExpired ? 'expired' : 'valid'}');
    
    return !isExpired;
  }

  bool _isDetailsCached(String userId) {
    final key = '${userId}_details';
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) {
      debugPrint('💾 [ProfileRepository] No cache timestamp found for details of user: $userId');
      return false;
    }
    
    final isExpired = DateTime.now().difference(timestamp) >= _cacheExpiration;
    debugPrint('💾 [ProfileRepository] Details cache for user $userId: ${isExpired ? 'expired' : 'valid'}');
    
    return !isExpired;
  }

  void _cacheProfile(String userId, ProfileData profile) {
    debugPrint('💾 [ProfileRepository] Caching profile for user: $userId');
    _profileCache[userId] = profile;
    _cacheTimestamps[userId] = DateTime.now();
  }

  void _cacheDetails(String userId, ProfileDetailsData details) {
    debugPrint('💾 [ProfileRepository] Caching details for user: $userId');
    _detailsCache[userId] = details;
    _cacheTimestamps['${userId}_details'] = DateTime.now();
  }

  void _clearUserCache(String userId) {
    debugPrint('🗑️ [ProfileRepository] Clearing cache for user: $userId');
    _profileCache.remove(userId);
    _detailsCache.remove(userId);
    _cacheTimestamps.remove(userId);
    _cacheTimestamps.remove('${userId}_details');
  }

  /// Clear all cached data
  void clearCache() {
    debugPrint('🗑️ [ProfileRepository] Clearing all cached data');
    debugPrint('📊 [ProfileRepository] Cache stats before clear: ${_profileCache.length} profiles, ${_detailsCache.length} details');
    
    _profileCache.clear();
    _detailsCache.clear();
    _cacheTimestamps.clear();
    
    debugPrint('✅ [ProfileRepository] All cache cleared successfully');
  }

  /// Validate profile data before saving
  ValidationResult validateBasicInfo({
    required String firstName,
    required String lastName,
    required int age,
    required String location,
  }) {
    debugPrint('🔄 [ProfileRepository] validateBasicInfo started');
    debugPrint('📝 [ProfileRepository] Input data: firstName="$firstName", lastName="$lastName", age=$age, location="$location"');
    
    final errors = <String, String>{};

    if (firstName.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
      debugPrint('❌ [ProfileRepository] Validation error: First name is empty');
    } else if (firstName.length < 2) {
      errors['firstName'] = 'First name must be at least 2 characters';
      debugPrint('❌ [ProfileRepository] Validation error: First name too short (${firstName.length} chars)');
    } else {
      debugPrint('✅ [ProfileRepository] First name validation passed');
    }

    if (lastName.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
      debugPrint('❌ [ProfileRepository] Validation error: Last name is empty');
    } else if (lastName.length < 2) {
      errors['lastName'] = 'Last name must be at least 2 characters';
      debugPrint('❌ [ProfileRepository] Validation error: Last name too short (${lastName.length} chars)');
    } else {
      debugPrint('✅ [ProfileRepository] Last name validation passed');
    }

    if (age < 18) {
      errors['age'] = 'You must be at least 18 years old';
      debugPrint('❌ [ProfileRepository] Validation error: Age too young ($age)');
    } else if (age > 100) {
      errors['age'] = 'Please enter a valid age';
      debugPrint('❌ [ProfileRepository] Validation error: Age too old ($age)');
    } else {
      debugPrint('✅ [ProfileRepository] Age validation passed');
    }

    if (location.trim().isEmpty) {
      errors['location'] = 'Location is required';
      debugPrint('❌ [ProfileRepository] Validation error: Location is empty');
    } else {
      debugPrint('✅ [ProfileRepository] Location validation passed');
    }

    final isValid = errors.isEmpty;
    debugPrint('📊 [ProfileRepository] Validation result: ${isValid ? 'PASSED' : 'FAILED'}');
    if (!isValid) {
      debugPrint('❌ [ProfileRepository] Validation errors: $errors');
    }

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