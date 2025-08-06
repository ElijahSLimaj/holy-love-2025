import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/profile_repository.dart';

part 'profile_creation_event.dart';
part 'profile_creation_state.dart';

class ProfileCreationBloc extends Bloc<ProfileCreationEvent, ProfileCreationState> {
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
    debugPrint('🔄 [ProfileCreationBloc] _onSaveBasicInfoRequested started');
    debugPrint('📝 [ProfileCreationBloc] Event data: firstName="${event.firstName}", lastName="${event.lastName}", age=${event.age}, location="${event.location}"');
    
    emit(ProfileCreationLoading());
    debugPrint('⏳ [ProfileCreationBloc] Emitted loading state');

    try {
      // Validate data first
      debugPrint('🔍 [ProfileCreationBloc] Validating basic info...');
      final validation = _profileRepository.validateBasicInfo(
        firstName: event.firstName,
        lastName: event.lastName,
        age: event.age,
        location: event.location,
      );

      debugPrint('📊 [ProfileCreationBloc] Validation result: ${validation.isValid ? 'PASSED' : 'FAILED'}');
      if (!validation.isValid) {
        debugPrint('❌ [ProfileCreationBloc] Validation failed: ${validation.errors}');
        emit(ProfileCreationError(
          message: 'Please fix the errors',
          fieldErrors: validation.errors,
        ));
        debugPrint('❌ [ProfileCreationBloc] Emitted error state');
        return;
      }

      // Save to Firestore
      debugPrint('💾 [ProfileCreationBloc] Saving basic info to Firestore...');
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

      debugPrint('✅ [ProfileCreationBloc] Basic info saved successfully');
      emit(const ProfileCreationStepCompleted(
        stepName: 'basicInfo',
        completedSteps: {'basicInfo': true},
      ));
      debugPrint('✅ [ProfileCreationBloc] Emitted step completed state');
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileCreationBloc] Error in _onSaveBasicInfoRequested: $e');
      debugPrint('📚 [ProfileCreationBloc] Stack trace: $stackTrace');
      emit(ProfileCreationError(
        message: 'Failed to save profile: ${e.toString()}',
      ));
      debugPrint('❌ [ProfileCreationBloc] Emitted error state');
    }
  }

  Future<void> _onValidateBasicInfoRequested(
    ValidateBasicInfoRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    debugPrint('🔄 [ProfileCreationBloc] _onValidateBasicInfoRequested started');
    debugPrint('📝 [ProfileCreationBloc] Event data: firstName="${event.firstName}", lastName="${event.lastName}", age=${event.age}, location="${event.location}"');
    
    final validation = _profileRepository.validateBasicInfo(
      firstName: event.firstName,
      lastName: event.lastName,
      age: event.age,
      location: event.location,
    );

    debugPrint('📊 [ProfileCreationBloc] Validation result: ${validation.isValid ? 'PASSED' : 'FAILED'}');
    if (validation.isValid) {
      debugPrint('✅ [ProfileCreationBloc] Emitting validation success state');
      emit(ProfileCreationValidationSuccess());
    } else {
      debugPrint('❌ [ProfileCreationBloc] Emitting validation error state: ${validation.errors}');
      emit(ProfileCreationValidationError(
        fieldErrors: validation.errors,
      ));
    }
  }

  Future<void> _onUpdateStepCompleted(
    UpdateStepCompleted event,
    Emitter<ProfileCreationState> emit,
  ) async {
    debugPrint('🔄 [ProfileCreationBloc] _onUpdateStepCompleted started');
    debugPrint('📝 [ProfileCreationBloc] Event data: stepName="${event.stepName}", completedSteps=${event.completedSteps}');
    
    emit(ProfileCreationStepCompleted(
      stepName: event.stepName,
      completedSteps: event.completedSteps,
    ));
    debugPrint('✅ [ProfileCreationBloc] Emitted step completed state');
  }

  Future<void> _onCompleteProfileRequested(
    CompleteProfileRequested event,
    Emitter<ProfileCreationState> emit,
  ) async {
    debugPrint('🔄 [ProfileCreationBloc] _onCompleteProfileRequested started');
    debugPrint('📝 [ProfileCreationBloc] Event data: ${event.allProfileData}');
    
    emit(ProfileCreationLoading());
    debugPrint('⏳ [ProfileCreationBloc] Emitted loading state');

    try {
      final userId = _profileRepository.currentUserId;
      debugPrint('👤 [ProfileCreationBloc] Current user ID: $userId');
      
      if (userId == null) {
        debugPrint('❌ [ProfileCreationBloc] User not authenticated');
        throw Exception('User not authenticated');
      }

      // Update profile completion status
      final updates = {
        'profileComplete': true,
        'profileCompletionPercentage': 100,
        'completedSteps': event.allProfileData['completedSteps'],
      };
      debugPrint('📝 [ProfileCreationBloc] Profile completion updates: $updates');
      
      await _profileRepository.batchUpdateProfile(userId, updates);

      debugPrint('✅ [ProfileCreationBloc] Profile completed successfully');
      emit(ProfileCreationCompleted());
      debugPrint('✅ [ProfileCreationBloc] Emitted completion state');
    } catch (e, stackTrace) {
      debugPrint('❌ [ProfileCreationBloc] Error in _onCompleteProfileRequested: $e');
      debugPrint('📚 [ProfileCreationBloc] Stack trace: $stackTrace');
      emit(ProfileCreationError(
        message: 'Failed to complete profile: ${e.toString()}',
      ));
      debugPrint('❌ [ProfileCreationBloc] Emitted error state');
    }
  }
}