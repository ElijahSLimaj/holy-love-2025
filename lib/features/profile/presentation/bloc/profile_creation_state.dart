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

class PhotoUploadInProgress extends ProfileCreationState {
  final int photoIndex;
  final double progress;

  const PhotoUploadInProgress({
    required this.photoIndex,
    required this.progress,
  });

  @override
  List<Object?> get props => [photoIndex, progress];
}

class PhotoUploadSuccess extends ProfileCreationState {
  final int photoIndex;
  final String photoUrl;
  final String thumbnailUrl;

  const PhotoUploadSuccess({
    required this.photoIndex,
    required this.photoUrl,
    required this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [photoIndex, photoUrl, thumbnailUrl];
}

class PhotoUploadError extends ProfileCreationState {
  final int photoIndex;
  final String message;

  const PhotoUploadError({
    required this.photoIndex,
    required this.message,
  });

  @override
  List<Object?> get props => [photoIndex, message];
}

class AllPhotosUploaded extends ProfileCreationState {
  final List<String> photoUrls;
  final String? mainPhotoUrl;
  final String? mainThumbnailUrl;

  const AllPhotosUploaded({
    required this.photoUrls,
    this.mainPhotoUrl,
    this.mainThumbnailUrl,
  });

  @override
  List<Object?> get props => [photoUrls, mainPhotoUrl, mainThumbnailUrl];
}

class ProfileCreationSuccess extends ProfileCreationState {
  final String message;

  const ProfileCreationSuccess({
    required this.message,
  });

  @override
  List<Object?> get props => [message];
}
