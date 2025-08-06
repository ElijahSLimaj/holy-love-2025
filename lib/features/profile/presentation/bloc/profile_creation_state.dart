part of 'profile_creation_bloc.dart';

abstract class ProfileCreationState extends Equatable {
  const ProfileCreationState();

  @override
  List<Object?> get props => [];
}

class ProfileCreationInitial extends ProfileCreationState {}

class ProfileCreationLoading extends ProfileCreationState {}

class ProfileCreationStepCompleted extends ProfileCreationState {
  final String stepName;
  final Map<String, bool> completedSteps;

  const ProfileCreationStepCompleted({
    required this.stepName,
    required this.completedSteps,
  });

  @override
  List<Object?> get props => [stepName, completedSteps];
}

class ProfileCreationError extends ProfileCreationState {
  final String message;
  final Map<String, String>? fieldErrors;

  const ProfileCreationError({
    required this.message,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, fieldErrors];
}

class ProfileCreationValidationSuccess extends ProfileCreationState {}

class ProfileCreationValidationError extends ProfileCreationState {
  final Map<String, String> fieldErrors;

  const ProfileCreationValidationError({
    required this.fieldErrors,
  });

  @override
  List<Object?> get props => [fieldErrors];
}

class ProfileCreationCompleted extends ProfileCreationState {}