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
