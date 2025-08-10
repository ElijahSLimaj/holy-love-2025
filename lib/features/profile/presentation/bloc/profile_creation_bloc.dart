import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/profile_repository.dart';

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
}
