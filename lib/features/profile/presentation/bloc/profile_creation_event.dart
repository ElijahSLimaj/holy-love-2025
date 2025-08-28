part of 'profile_creation_bloc.dart';

abstract class ProfileCreationEvent extends Equatable {
  const ProfileCreationEvent();

  @override
  List<Object?> get props => [];
}

class SaveBasicInfoRequested extends ProfileCreationEvent {
  final String firstName;
  final String lastName;
  final int age;
  final String location;
  final GeoPoint? geoLocation;
  final String? locationCity;
  final String? locationState;
  final String? locationCountry;

  const SaveBasicInfoRequested({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.location,
    this.geoLocation,
    this.locationCity,
    this.locationState,
    this.locationCountry,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        age,
        location,
        geoLocation,
        locationCity,
        locationState,
        locationCountry,
      ];
}

class ValidateBasicInfoRequested extends ProfileCreationEvent {
  final String firstName;
  final String lastName;
  final int age;
  final String location;

  const ValidateBasicInfoRequested({
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.location,
  });

  @override
  List<Object?> get props => [firstName, lastName, age, location];
}

class UpdateStepCompleted extends ProfileCreationEvent {
  final String stepName;
  final Map<String, bool> completedSteps;

  const UpdateStepCompleted({
    required this.stepName,
    required this.completedSteps,
  });

  @override
  List<Object?> get props => [stepName, completedSteps];
}

class CompleteProfileRequested extends ProfileCreationEvent {
  final Map<String, dynamic> allProfileData;

  const CompleteProfileRequested({
    required this.allProfileData,
  });

  @override
  List<Object?> get props => [allProfileData];
}

class SavePhotosRequested extends ProfileCreationEvent {
  final List<String> photoPaths;

  const SavePhotosRequested({
    required this.photoPaths,
  });

  @override
  List<Object?> get props => [photoPaths];
}

class UploadPhotoRequested extends ProfileCreationEvent {
  final String photoPath;
  final int index;

  const UploadPhotoRequested({
    required this.photoPath,
    required this.index,
  });

  @override
  List<Object?> get props => [photoPath, index];
}

class SaveFaithInfoRequested extends ProfileCreationEvent {
  final String? denomination;
  final String? churchAttendance;
  final String? favoriteBibleVerse;
  final String? faithStory;

  const SaveFaithInfoRequested({
    this.denomination,
    this.churchAttendance,
    this.favoriteBibleVerse,
    this.faithStory,
  });

  @override
  List<Object?> get props => [
    denomination,
    churchAttendance,
    favoriteBibleVerse,
    faithStory,
  ];
}

class SaveAboutInfoRequested extends ProfileCreationEvent {
  final String? bio;
  final List<String> interests;
  final String? relationshipGoal;

  const SaveAboutInfoRequested({
    this.bio,
    required this.interests,
    this.relationshipGoal,
  });

  @override
  List<Object?> get props => [
    bio,
    interests,
    relationshipGoal,
  ];
}

class SavePreferencesInfoRequested extends ProfileCreationEvent {
  final int ageRangeMin;
  final int ageRangeMax;
  final int maxDistance;
  final String? faithImportance;
  final List<String> dealBreakers;

  const SavePreferencesInfoRequested({
    required this.ageRangeMin,
    required this.ageRangeMax,
    required this.maxDistance,
    this.faithImportance,
    required this.dealBreakers,
  });

  @override
  List<Object?> get props => [
    ageRangeMin,
    ageRangeMax,
    maxDistance,
    faithImportance,
    dealBreakers,
  ];
}
