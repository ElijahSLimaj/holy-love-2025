class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String location;
  final List<String> photoUrls;
  final String bio;
  final String denomination;
  final String churchAttendance;
  final String favoriteVerse;
  final String faithStory;
  final List<String> interests;
  final String relationshipGoal;
  final int distanceKm;
  final bool isOnline;
  final DateTime lastSeen;
  final String occupation;
  final String education;
  final List<String> languages;
  final String height;
  final bool hasChildren;
  final bool wantsChildren;
  final bool drinks;
  final bool smokes;
  final String personalityType;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.location,
    required this.photoUrls,
    required this.bio,
    required this.denomination,
    required this.churchAttendance,
    required this.favoriteVerse,
    required this.faithStory,
    required this.interests,
    required this.relationshipGoal,
    required this.distanceKm,
    required this.isOnline,
    required this.lastSeen,
    required this.occupation,
    required this.education,
    required this.languages,
    required this.height,
    required this.hasChildren,
    required this.wantsChildren,
    required this.drinks,
    required this.smokes,
    required this.personalityType,
  });

  String get fullName => '$firstName $lastName';
  String get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : '';
  
  String get ageLocationText => '$age • $location';
  
  String get distanceText {
    if (distanceKm < 1) return 'Less than 1 km away';
    if (distanceKm == 1) return '1 km away';
    return '$distanceKm km away';
  }

  String get onlineStatusText {
    if (isOnline) return 'Online now';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Last seen ${difference.inDays}d ago';
    }
  }

  // Convert to/from JSON for future API integration
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'location': location,
      'photoUrls': photoUrls,
      'bio': bio,
      'denomination': denomination,
      'churchAttendance': churchAttendance,
      'favoriteVerse': favoriteVerse,
      'faithStory': faithStory,
      'interests': interests,
      'relationshipGoal': relationshipGoal,
      'distanceKm': distanceKm,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'occupation': occupation,
      'education': education,
      'languages': languages,
      'height': height,
      'hasChildren': hasChildren,
      'wantsChildren': wantsChildren,
      'drinks': drinks,
      'smokes': smokes,
      'personalityType': personalityType,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      age: json['age'],
      location: json['location'],
      photoUrls: List<String>.from(json['photoUrls']),
      bio: json['bio'],
      denomination: json['denomination'],
      churchAttendance: json['churchAttendance'],
      favoriteVerse: json['favoriteVerse'],
      faithStory: json['faithStory'],
      interests: List<String>.from(json['interests']),
      relationshipGoal: json['relationshipGoal'],
      distanceKm: json['distanceKm'],
      isOnline: json['isOnline'],
      lastSeen: DateTime.parse(json['lastSeen']),
      occupation: json['occupation'],
      education: json['education'],
      languages: List<String>.from(json['languages']),
      height: json['height'],
      hasChildren: json['hasChildren'],
      wantsChildren: json['wantsChildren'],
      drinks: json['drinks'],
      smokes: json['smokes'],
      personalityType: json['personalityType'],
    );
  }

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    int? age,
    String? location,
    List<String>? photoUrls,
    String? bio,
    String? denomination,
    String? churchAttendance,
    String? favoriteVerse,
    String? faithStory,
    List<String>? interests,
    String? relationshipGoal,
    int? distanceKm,
    bool? isOnline,
    DateTime? lastSeen,
    String? occupation,
    String? education,
    List<String>? languages,
    String? height,
    bool? hasChildren,
    bool? wantsChildren,
    bool? drinks,
    bool? smokes,
    String? personalityType,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      bio: bio ?? this.bio,
      denomination: denomination ?? this.denomination,
      churchAttendance: churchAttendance ?? this.churchAttendance,
      favoriteVerse: favoriteVerse ?? this.favoriteVerse,
      faithStory: faithStory ?? this.faithStory,
      interests: interests ?? this.interests,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      distanceKm: distanceKm ?? this.distanceKm,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      languages: languages ?? this.languages,
      height: height ?? this.height,
      hasChildren: hasChildren ?? this.hasChildren,
      wantsChildren: wantsChildren ?? this.wantsChildren,
      drinks: drinks ?? this.drinks,
      smokes: smokes ?? this.smokes,
      personalityType: personalityType ?? this.personalityType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 