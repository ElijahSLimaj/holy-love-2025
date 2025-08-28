import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/profile_creation_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/profile_step_basic_info.dart';
import '../widgets/profile_step_photos.dart';
import '../widgets/profile_step_faith.dart';
import '../widgets/profile_step_about.dart';
import '../widgets/profile_step_preferences.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();

  late AnimationController _progressController;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final int _totalSteps = 5;

  // Profile data
  final Map<String, dynamic> _profileData = {};
  Map<String, bool> _completedSteps = {};

  // Step widget keys
  final GlobalKey<ProfileStepBasicInfoState> _basicInfoKey = GlobalKey();
  final GlobalKey<ProfileStepPhotosState> _photosKey = GlobalKey();
  final GlobalKey<ProfileStepFaithState> _faithKey = GlobalKey();
  final GlobalKey<ProfileStepAboutState> _aboutKey = GlobalKey();
  final GlobalKey<ProfileStepPreferencesState> _preferencesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingProfileAndStartAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _loadExistingProfileAndStartAnimations() async {
    // Load existing profile data to determine starting step
    final profileRepository = ProfileRepository();
    final userId = profileRepository.currentUserId;
    
    if (userId != null) {
      try {
        final existingProfile = await profileRepository.getProfile(userId);
        if (existingProfile != null) {
          // Populate profile data from existing profile
          _profileData.addAll({
            'firstName': existingProfile.firstName,
            'lastName': existingProfile.lastName,
            'age': existingProfile.age,
            'location': existingProfile.location,
            'geoLocation': existingProfile.geoLocation,
            'locationCity': existingProfile.locationCity,
            'locationState': existingProfile.locationState,
            'locationCountry': existingProfile.locationCountry,
          });

          // Store completed steps
          _completedSteps = Map<String, bool>.from(existingProfile.completedSteps);

          // Load profile details if they exist
          final profileDetails = await profileRepository.getProfileDetails(userId);
          if (profileDetails != null) {
            // Add profile details data to _profileData
            _profileData.addAll({
              'denomination': profileDetails.denomination,
              'churchAttendance': profileDetails.churchAttendance,
              'favoriteBibleVerse': profileDetails.favoriteBibleVerse,
              'faithStory': profileDetails.faithStory,
              'bio': profileDetails.bio,
              'interests': profileDetails.interests,
              'relationshipGoal': profileDetails.relationshipGoal,
              'occupation': profileDetails.occupation,
              'education': profileDetails.education,
              'languages': profileDetails.languages,
              'height': profileDetails.height,
              'hasChildren': profileDetails.hasChildren,
              'wantsChildren': profileDetails.wantsChildren,
              'drinks': profileDetails.drinks,
              'smokes': profileDetails.smokes,
              'personalityType': profileDetails.personalityType,
              'preferences': profileDetails.preferences,
            });
          }

          // Determine which step to start from
          final nextStep = _determineNextStep(existingProfile.completedSteps);
          if (nextStep > 0) {
            setState(() {
              _currentStep = nextStep;
            });
            
            // Jump to the appropriate page
            _pageController.animateToPage(
              nextStep,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      } catch (e) {
        // If loading fails, start from beginning
        debugPrint('Error loading existing profile: $e');
      }
    }
    
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        _slideController.forward();
        _updateProgress();
      }
    }
  }

  /// Determine which step to start from based on completed steps
  int _determineNextStep(Map<String, bool> completedSteps) {
    const stepOrder = ['basicInfo', 'photos', 'faith', 'about', 'preferences'];
    
    for (int i = 0; i < stepOrder.length; i++) {
      final stepName = stepOrder[i];
      final isCompleted = completedSteps[stepName] ?? false;
      
      if (!isCompleted) {
        return i; // Return the index of the first incomplete step
      }
    }
    
    // All steps completed, go to last step
    return stepOrder.length - 1;
  }

  void _updateProgress() {
    final targetProgress = (_currentStep + 1) / _totalSteps;
    _progressController.animateTo(targetProgress);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCreationBloc, ProfileCreationState>(
        listener: (context, state) {
          if (state is ProfileCreationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            );
          } else if (state is ProfileCreationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
            );
            // Refresh auth state and navigate after a short delay
            Future.delayed(const Duration(milliseconds: 500), () async {
              if (mounted) {
                // Refresh the auth state to update isNewUser status
                context.read<AuthBloc>().add(const AuthRefreshUserRequested());
                
                // Wait a bit for the auth refresh to complete
                await Future.delayed(const Duration(milliseconds: 1000));
                
                if (mounted) {
                  _navigateToMainApp();
                }
              }
            });
          }
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.lightGray,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header with progress
                  _buildHeader(),

                  // Page content
                  Expanded(
                    child: _buildPageView(),
                  ),

                  // Navigation buttons
                  _buildNavigationButtons(),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            // Back button and step indicator
            Row(
              children: [
                IconButton(
                  onPressed: _currentStep > 0 ? _previousStep : _handleBack,
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textPrimary,
                    size: AppDimensions.iconM,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentStep + 1} of $_totalSteps',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacing20),

            // Progress bar
            _buildProgressBar(),

            const SizedBox(height: AppDimensions.spacing24),

            // Step title with completion indicator
            SlideTransition(
              position: _slideAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isCurrentStepCompleted())
                    Container(
                      margin: const EdgeInsets.only(right: AppDimensions.spacing8),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      _getStepTitle(),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacing8),

            // Step subtitle
            SlideTransition(
              position: _slideAnimation,
              child: Text(
                _getStepSubtitle(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ProfileStepBasicInfo(
              key: _basicInfoKey,
              profileData: _profileData,
              onDataChanged: _updateProfileData,
              onStepCompleted: () {
                // Move to next step after successful save
                _moveToNextStepAfterSave();
              },
            ),
            ProfileStepPhotos(
              key: _photosKey,
              profileData: _profileData,
              onDataChanged: _updateProfileData,
              onStepCompleted: () {
                _moveToNextStepAfterSave();
              },
            ),
            ProfileStepFaith(
              key: _faithKey,
              profileData: _profileData,
              onDataChanged: _updateProfileData,
              onStepCompleted: () {
                _moveToNextStepAfterSave();
              },
            ),
            ProfileStepAbout(
              key: _aboutKey,
              profileData: _profileData,
              onDataChanged: _updateProfileData,
              onStepCompleted: () {
                _moveToNextStepAfterSave();
              },
            ),
            ProfileStepPreferences(
              key: _preferencesKey,
              profileData: _profileData,
              onDataChanged: _updateProfileData,
              onStepCompleted: () {
                _completeProfileCreation();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          children: [
            // Skip button (for optional steps)
            if (_canSkipCurrentStep())
              Expanded(
                child: CustomButton(
                  text: AppStrings.skip,
                  onPressed: _nextStep,
                  variant: ButtonVariant.text,
                  isFullWidth: true,
                ),
              ),

            if (_canSkipCurrentStep())
              const SizedBox(width: AppDimensions.spacing16),

            // Continue/Finish button
            Expanded(
              flex: _canSkipCurrentStep() ? 2 : 1,
              child: CustomButton(
                text: _currentStep == _totalSteps - 1
                    ? 'Complete Profile'
                    : AppStrings.continueText,
                onPressed: _isCurrentStepValid() ? _nextStep : null,
                variant: ButtonVariant.primary,
                isFullWidth: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step management
  void _nextStep() async {
    // Save data for specific steps before proceeding
    if (_currentStep == 0) {
      // Save basic info to Firestore
      _basicInfoKey.currentState?.saveBasicInfo();
      // The actual navigation will happen via the onStepCompleted callback
      return;
    } else if (_currentStep == 1) {
      // Save photos to Firebase Storage
      _photosKey.currentState?.savePhotos();
      // The actual navigation will happen via the onStepCompleted callback
      return;
    } else if (_currentStep == 2) {
      // Save faith info to Firestore
      _faithKey.currentState?.saveFaithInfo();
      // The actual navigation will happen via the onStepCompleted callback
      return;
    } else if (_currentStep == 3) {
      // Save about info to Firestore
      _aboutKey.currentState?.saveAboutInfo();
      // The actual navigation will happen via the onStepCompleted callback
      return;
    } else if (_currentStep == 4) {
      // Save preferences info and complete profile
      _preferencesKey.currentState?.savePreferencesInfo();
      // The completion will happen via the onStepCompleted callback
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      // Animate out current step
      await _slideController.reverse();

      setState(() {
        _currentStep++;
      });

      // Update page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Animate in new step
      _slideController.forward();
      _updateProgress();

      // Haptic feedback
      HapticFeedback.lightImpact();
    } else {
      // Complete profile creation
      _completeProfileCreation();
    }
  }

  void _moveToNextStepAfterSave() async {
    if (_currentStep < _totalSteps - 1) {
      // Mark current step as completed
      const stepOrder = ['basicInfo', 'photos', 'faith', 'about', 'preferences'];
      if (_currentStep >= 0 && _currentStep < stepOrder.length) {
        setState(() {
          _completedSteps[stepOrder[_currentStep]] = true;
        });
      }

      // Animate out current step
      await _slideController.reverse();

      setState(() {
        _currentStep++;
      });

      // Update page
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Animate in new step
      _slideController.forward();
      _updateProgress();

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() async {
    if (_currentStep > 0) {
      // Animate out current step
      await _slideController.reverse();

      setState(() {
        _currentStep--;
      });

      // Update page
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Animate in previous step
      _slideController.forward();
      _updateProgress();

      // Haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _handleBack() {
    Navigator.of(context).pop();
  }

  void _updateProfileData(String key, dynamic value) {
    setState(() {
      _profileData[key] = value;
    });
  }

  void _completeProfileCreation() async {
    // This method is now handled by the preferences step completion
    // The BLocListener will handle the ProfileCreationSuccess state
    debugPrint('Profile creation completed - handled by BLoC listener');
  }



  void _navigateToMainApp() {
    // Close any open dialogs
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    
    // Pop to root and let the auth bloc handle navigation
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // The _AppNavigator will automatically route to MainNavigationScreen
    // since the user's profileComplete is now true
  }

  // Helper methods
  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return AppStrings.profileStep1;
      case 1:
        return AppStrings.profileStep2;
      case 2:
        return AppStrings.profileStep4;
      case 3:
        return AppStrings.profileStep3;
      case 4:
        return AppStrings.profileStep5;
      default:
        return '';
    }
  }

  bool _isCurrentStepCompleted() {
    const stepOrder = ['basicInfo', 'photos', 'faith', 'about', 'preferences'];
    if (_currentStep >= 0 && _currentStep < stepOrder.length) {
      final stepName = stepOrder[_currentStep];
      return _completedSteps[stepName] ?? false;
    }
    return false;
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Tell us a bit about yourself';
      case 1:
        return 'Add photos that show your personality';
      case 2:
        return 'Share your faith journey with us';
      case 3:
        return 'Help others get to know you better';
      case 4:
        return 'Set your preferences for matches';
      default:
        return '';
    }
  }

  bool _canSkipCurrentStep() {
    // Only allow skipping optional steps
    return _currentStep == 1 || _currentStep == 3; // Photos and About steps
  }

  bool _isCurrentStepValid() {
    // TODO: Implement validation for each step
    switch (_currentStep) {
      case 0: // Basic info
        return _profileData['firstName'] != null && _profileData['age'] != null;
      case 1: // Photos
        return true; // Optional step
      case 2: // Faith
        return _profileData['denomination'] != null;
      case 3: // About
        return true; // Optional step
      case 4: // Preferences
        return _profileData['ageRange'] != null;
      default:
        return false;
    }
  }
}
