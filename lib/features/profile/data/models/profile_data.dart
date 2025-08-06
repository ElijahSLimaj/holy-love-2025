import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileData {
  // Basic Info
  final String userId;
  final String firstName;
  final String lastName;
  final int age;
  final DateTime birthDate;
  final String location;
  final GeoPoint? geoLocation;
  final String? locationCity;
  final String? locationState;
  final String? locationCountry;
  
  // Profile Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool profileComplete;
  final int profileCompletionPercentage;
  final Map<String, bool> completedSteps;
  
  // Search Optimization Fields
  final String searchName; // Lowercase for case-insensitive search
  final List<String> searchKeywords; // For text search
  final int ageGroup; // For age range queries (e.g., 20, 25, 30)
  
  // Denormalized fields for performance
  final String? mainPhotoUrl; // Avoid extra reads for profile cards
  final String? mainPhotoThumbnailUrl; // Small size for list views
  
  ProfileData({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.birthDate,
    required this.location,
    this.geoLocation,
    this.locationCity,
    this.locationState,
    this.locationCountry,
    required this.createdAt,
    required this.updatedAt,
    required this.profileComplete,
    required this.profileCompletionPercentage,
    required this.completedSteps,
    required this.searchName,
    required this.searchKeywords,
    required this.ageGroup,
    this.mainPhotoUrl,
    this.mainPhotoThumbnailUrl,
  });

  /// Calculate age group for efficient age range queries
  static int calculateAgeGroup(int age) {
    return (age ~/ 5) * 5; // Groups: 20-24, 25-29, 30-34, etc.
  }

  /// Generate search keywords for text search
  static List<String> generateSearchKeywords(String firstName, String lastName, String location) {
    final keywords = <String>[];
    
    // Add full names
    keywords.add(firstName.toLowerCase());
    keywords.add(lastName.toLowerCase());
    keywords.add('${firstName.toLowerCase()} ${lastName.toLowerCase()}');
    
    // Add partial names for autocomplete
    for (int i = 1; i <= firstName.length && i <= 3; i++) {
      keywords.add(firstName.substring(0, i).toLowerCase());
    }
    
    // Add location keywords
    final locationParts = location.split(',').map((e) => e.trim().toLowerCase());
    keywords.addAll(locationParts);
    
    return keywords.toSet().toList(); // Remove duplicates
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'birthDate': Timestamp.fromDate(birthDate),
      'location': location,
      'geoLocation': geoLocation,
      'locationCity': locationCity,
      'locationState': locationState,
      'locationCountry': locationCountry,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'profileComplete': profileComplete,
      'profileCompletionPercentage': profileCompletionPercentage,
      'completedSteps': completedSteps,
      'searchName': searchName,
      'searchKeywords': searchKeywords,
      'ageGroup': ageGroup,
      'mainPhotoUrl': mainPhotoUrl,
      'mainPhotoThumbnailUrl': mainPhotoThumbnailUrl,
      // Denormalized fields for efficient filtering
      '_age_ageGroup': '${age}_$ageGroup', // Composite index for age queries
      '_location_lower': location.toLowerCase(), // For location searches
    };
  }

  factory ProfileData.fromFirestore(Map<String, dynamic> data) {
    debugPrint('🔄 [ProfileData] fromFirestore started with data: $data');
    
    // Handle null timestamps safely
    final createdAt = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
    final updatedAt = data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now();
    final birthDate = data['birthDate'] != null ? (data['birthDate'] as Timestamp).toDate() : DateTime.now();
    
    debugPrint('📅 [ProfileData] Parsed timestamps - createdAt: $createdAt, updatedAt: $updatedAt, birthDate: $birthDate');
    
    final profileData = ProfileData(
      userId: data['userId'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      age: data['age'] ?? 0,
      birthDate: birthDate,
      location: data['location'] ?? '',
      geoLocation: data['geoLocation'] as GeoPoint?,
      locationCity: data['locationCity'],
      locationState: data['locationState'],
      locationCountry: data['locationCountry'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      profileComplete: data['profileComplete'] ?? false,
      profileCompletionPercentage: data['profileCompletionPercentage'] ?? 0,
      completedSteps: Map<String, bool>.from(data['completedSteps'] ?? {}),
      searchName: data['searchName'] ?? '',
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
      ageGroup: data['ageGroup'] ?? 0,
      mainPhotoUrl: data['mainPhotoUrl'],
      mainPhotoThumbnailUrl: data['mainPhotoThumbnailUrl'],
    );
    
    debugPrint('✅ [ProfileData] Successfully created ProfileData object');
    return profileData;
  }

  ProfileData copyWith({
    String? firstName,
    String? lastName,
    int? age,
    DateTime? birthDate,
    String? location,
    GeoPoint? geoLocation,
    String? locationCity,
    String? locationState,
    String? locationCountry,
    DateTime? updatedAt,
    bool? profileComplete,
    int? profileCompletionPercentage,
    Map<String, bool>? completedSteps,
    String? mainPhotoUrl,
    String? mainPhotoThumbnailUrl,
  }) {
    final newFirstName = firstName ?? this.firstName;
    final newLastName = lastName ?? this.lastName;
    final newAge = age ?? this.age;
    final newLocation = location ?? this.location;
    
    return ProfileData(
      userId: userId,
      firstName: newFirstName,
      lastName: newLastName,
      age: newAge,
      birthDate: birthDate ?? this.birthDate,
      location: newLocation,
      geoLocation: geoLocation ?? this.geoLocation,
      locationCity: locationCity ?? this.locationCity,
      locationState: locationState ?? this.locationState,
      locationCountry: locationCountry ?? this.locationCountry,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      profileComplete: profileComplete ?? this.profileComplete,
      profileCompletionPercentage: profileCompletionPercentage ?? this.profileCompletionPercentage,
      completedSteps: completedSteps ?? this.completedSteps,
      searchName: '${newFirstName.toLowerCase()} ${newLastName.toLowerCase()}',
      searchKeywords: generateSearchKeywords(newFirstName, newLastName, newLocation),
      ageGroup: calculateAgeGroup(newAge),
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      mainPhotoThumbnailUrl: mainPhotoThumbnailUrl ?? this.mainPhotoThumbnailUrl,
    );
  }
}

/// Extended profile data stored in subcollection for detailed view
/// This separates frequently accessed data from detailed data
class ProfileDetailsData {
  // Faith Information
  final String? denomination;
  final String? churchAttendance;
  final String? favoriteBibleVerse;
  final String? faithStory;
  
  // About Information
  final String? bio;
  final List<String> interests;
  final String? relationshipGoal;
  
  // Additional Details
  final String? occupation;
  final String? education;
  final List<String> languages;
  final String? height;
  final bool? hasChildren;
  final bool? wantsChildren;
  final bool? drinks;
  final bool? smokes;
  final String? personalityType;
  
  // Preferences
  final Map<String, dynamic>? preferences;
  
  ProfileDetailsData({
    this.denomination,
    this.churchAttendance,
    this.favoriteBibleVerse,
    this.faithStory,
    this.bio,
    required this.interests,
    this.relationshipGoal,
    this.occupation,
    this.education,
    required this.languages,
    this.height,
    this.hasChildren,
    this.wantsChildren,
    this.drinks,
    this.smokes,
    this.personalityType,
    this.preferences,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'denomination': denomination,
      'churchAttendance': churchAttendance,
      'favoriteBibleVerse': favoriteBibleVerse,
      'faithStory': faithStory,
      'bio': bio,
      'interests': interests,
      'relationshipGoal': relationshipGoal,
      'occupation': occupation,
      'education': education,
      'languages': languages,
      'height': height,
      'hasChildren': hasChildren,
      'wantsChildren': wantsChildren,
      'drinks': drinks,
      'smokes': smokes,
      'personalityType': personalityType,
      'preferences': preferences,
    };
  }

  factory ProfileDetailsData.fromFirestore(Map<String, dynamic> data) {
    return ProfileDetailsData(
      denomination: data['denomination'],
      churchAttendance: data['churchAttendance'],
      favoriteBibleVerse: data['favoriteBibleVerse'],
      faithStory: data['faithStory'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      relationshipGoal: data['relationshipGoal'],
      occupation: data['occupation'],
      education: data['education'],
      languages: List<String>.from(data['languages'] ?? []),
      height: data['height'],
      hasChildren: data['hasChildren'],
      wantsChildren: data['wantsChildren'],
      drinks: data['drinks'],
      smokes: data['smokes'],
      personalityType: data['personalityType'],
      preferences: data['preferences'],
    );
  }
}