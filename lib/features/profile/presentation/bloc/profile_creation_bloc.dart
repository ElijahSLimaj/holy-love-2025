import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../../core/services/image_upload_service.dart';

part 'profile_creation_event.dart';
part 'profile_creation_state.dart';

class ProfileCreationBloc
    extends Bloc<ProfileCreationEvent, ProfileCreationState> {
  final ProfileRepository _profileRepository;

  ProfileCreationBloc({
    required ProfileRepository profileRepository,
  })  : _profileRepository = profileRepository,
        super(ProfileCreationInitial()) {
    on<SaveBasicInfoRequested>(_onSaveBasicInfoRequested);
    on<ValidateBasicInfoRequested>(_onValidateBasicInfoRequested);
    on<UpdateStepCompleted>(_onUpdateStepCompleted);
    on<CompleteProfileRequested>(_onCompleteProfileRequested);
    on<SavePhotosRequested>(_onSavePhotosRequested);
    on<UploadPhotoRequested>(_onUploadPhotoRequested);
    on<SaveFaithInfoRequested>(_onSaveFaithInfoRequested);
    on<SaveAboutInfoRequested>(_onSaveAboutInfoRequested);
    on<SavePreferencesInfoRequested>(_onSavePreferencesInfoRequested);
  }

  Future<void> _onSaveBasicInfoRequested(
    SaveBasicInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    // removed debugPrint

    emit(ProfileCreationLoading());

    try {
      // Validate data first

      final validation = _profileRepository.validateBasicInfo(
        firstName: event.firstName,
        lastName: event.lastName,
        age: event.age,
        location: event.location,
      );

      if (!validation.isValid) {
        emit(ProfileCreationError(
          message: 'Please fix the errors',
          fieldErrors: validation.errors,
        ));

        return;
      }

      // Save to Firestore

      await _profileRepository.saveBasicInfo(
        firstName: event.firstName,
        lastName: event.lastName,
        age: event.age,
        location: event.location,
        geoLocation: event.geoLocation,
        locationCity: event.locationCity,
        locationState: event.locationState,
        locationCountry: event.locationCountry,
      );

      emit(const ProfileCreationStepCompleted(
        stepName: 'basicInfo',
        completedSteps: {'basicInfo': true},
      ));
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to save profile: ${e.toString()}',
      ));
    }
  }

  Future<void> _onValidateBasicInfoRequested(
    ValidateBasicInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    // removed debugPrint

    final validation = _profileRepository.validateBasicInfo(
      firstName: event.firstName,
      lastName: event.lastName,
      age: event.age,
      location: event.location,
    );

    if (validation.isValid) {
      emit(ProfileCreationValidationSuccess());
    } else {
      emit(ProfileCreationValidationError(
        fieldErrors: validation.errors,
      ));
    }
  }

  Future<void> _onUpdateStepCompleted(
    UpdateStepCompleted event,
    Emitter<ProfileCreationState> emit,
  ) async {
    // removed debugPrint

    emit(ProfileCreationStepCompleted(
      stepName: event.stepName,
      completedSteps: event.completedSteps,
    ));
  }

  Future<void> _onCompleteProfileRequested(
    CompleteProfileRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    // removed debugPrint

    emit(ProfileCreationLoading());

    try {
      final userId = _profileRepository.currentUserId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update profile completion status
      final updates = {
        'profileComplete': true,
        'profileCompletionPercentage': 100,
        'completedSteps': event.allProfileData['completedSteps'],
      };

      await _profileRepository.batchUpdateProfile(userId, updates);

      emit(ProfileCreationCompleted());
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to complete profile: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSavePhotosRequested(
    SavePhotosRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    if (event.photoPaths.isEmpty) {
      // No photos to upload, mark step as completed
      emit(const ProfileCreationStepCompleted(
        stepName: 'photos',
        completedSteps: {'photos': true},
      ));
      return;
    }

    emit(ProfileCreationLoading());

    try {
      final userId = _profileRepository.currentUserId;
      debugPrint('Current user ID for photo upload: $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final uploadResults = <ImageUploadResult>[];
      
      // Upload photos one by one with progress updates
      for (int i = 0; i < event.photoPaths.length; i++) {
        emit(PhotoUploadInProgress(photoIndex: i, progress: 0.0));
        
        // Validate file exists before uploading
        final file = File(event.photoPaths[i]);
        debugPrint('Checking file: ${event.photoPaths[i]}');
        debugPrint('File exists: ${await file.exists()}');
        
        if (!await file.exists()) {
          emit(PhotoUploadError(
            photoIndex: i,
            message: 'Photo file not found: ${event.photoPaths[i]}',
          ));
          return;
        }
        
        final result = await ImageUploadService.uploadProfileImage(
          file,
          userId,
          customFileName: 'profile_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          onProgress: (progress) {
            emit(PhotoUploadInProgress(photoIndex: i, progress: progress));
          },
        );

        if (result != null) {
          uploadResults.add(result);
          emit(PhotoUploadSuccess(
            photoIndex: i,
            photoUrl: result.originalUrl,
            thumbnailUrl: result.thumbnailUrl,
          ));
        } else {
          emit(PhotoUploadError(
            photoIndex: i,
            message: 'Failed to upload photo ${i + 1}',
          ));
          return;
        }
      }

      // Update profile with photo URLs
      final photoUrls = uploadResults.map((r) => r.originalUrl).toList();
      final thumbnailUrls = uploadResults.map((r) => r.thumbnailUrl).toList();
      
      // Save main photo (first one) to profile
      final mainPhotoUrl = photoUrls.isNotEmpty ? photoUrls.first : null;
      final mainThumbnailUrl = thumbnailUrls.isNotEmpty ? thumbnailUrls.first : null;

      await _profileRepository.savePhotos(
        userId: userId,
        photoUrls: photoUrls,
        thumbnailUrls: thumbnailUrls,
        mainPhotoUrl: mainPhotoUrl,
        mainThumbnailUrl: mainThumbnailUrl,
      );

      emit(AllPhotosUploaded(
        photoUrls: photoUrls,
        mainPhotoUrl: mainPhotoUrl,
        mainThumbnailUrl: mainThumbnailUrl,
      ));

      emit(const ProfileCreationStepCompleted(
        stepName: 'photos',
        completedSteps: {'photos': true},
      ));
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to upload photos: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUploadPhotoRequested(
    UploadPhotoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    emit(PhotoUploadInProgress(photoIndex: event.index, progress: 0.0));

    try {
      final userId = _profileRepository.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final result = await ImageUploadService.uploadProfileImage(
        File(event.photoPath),
        userId,
        customFileName: 'profile_${event.index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (progress) {
          emit(PhotoUploadInProgress(photoIndex: event.index, progress: progress));
        },
      );

      if (result != null) {
        emit(PhotoUploadSuccess(
          photoIndex: event.index,
          photoUrl: result.originalUrl,
          thumbnailUrl: result.thumbnailUrl,
        ));
      } else {
        emit(PhotoUploadError(
          photoIndex: event.index,
          message: 'Failed to upload photo',
        ));
      }
    } catch (e) {
      emit(PhotoUploadError(
        photoIndex: event.index,
        message: 'Upload failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSaveFaithInfoRequested(
    SaveFaithInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    emit(ProfileCreationLoading());

    try {
      final userId = _profileRepository.currentUserId;
      debugPrint('Current user ID for faith save: $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _profileRepository.saveFaithInfo(
        userId: userId,
        denomination: event.denomination,
        churchAttendance: event.churchAttendance,
        favoriteBibleVerse: event.favoriteBibleVerse,
        faithStory: event.faithStory,
      );

      emit(const ProfileCreationStepCompleted(
        stepName: 'faith',
        completedSteps: {'faith': true},
      ));
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to save faith information: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSaveAboutInfoRequested(
    SaveAboutInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    emit(ProfileCreationLoading());

    try {
      final userId = _profileRepository.currentUserId;
      debugPrint('Current user ID for about save: $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _profileRepository.saveAboutInfo(
        userId: userId,
        bio: event.bio,
        interests: event.interests,
        relationshipGoal: event.relationshipGoal,
      );

      emit(const ProfileCreationStepCompleted(
        stepName: 'about',
        completedSteps: {'about': true},
      ));
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to save about information: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSavePreferencesInfoRequested(
    SavePreferencesInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    emit(ProfileCreationLoading());

    try {
      final userId = _profileRepository.currentUserId;
      debugPrint('Current user ID for preferences save: $userId');
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _profileRepository.savePreferencesInfo(
        userId: userId,
        ageRangeMin: event.ageRangeMin,
        ageRangeMax: event.ageRangeMax,
        maxDistance: event.maxDistance,
        faithImportance: event.faithImportance,
        dealBreakers: event.dealBreakers,
      );

      // Mark profile as fully completed
      emit(const ProfileCreationStepCompleted(
        stepName: 'preferences',
        completedSteps: {'preferences': true},
      ));
      
      // Emit profile completion success
      emit(const ProfileCreationSuccess(
        message: 'Profile created successfully! Welcome to Holy Love!',
      ));
    } catch (e) {
      emit(ProfileCreationError(
        message: 'Failed to save preferences: ${e.toString()}',
      ));
    }
  }
}
