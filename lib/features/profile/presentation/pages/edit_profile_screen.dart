import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../discovery/data/mock_users.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _sectionController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sectionFadeAnimation;

  late ScrollController _scrollController;

  // Form controllers
  final _bioController = TextEditingController();
  final _occupationController = TextEditingController();
  final _educationController = TextEditingController();
  final _heightController = TextEditingController();
  final _favoriteVerseController = TextEditingController();
  final _faithStoryController = TextEditingController();

  // Form data
  List<String> _selectedInterests = [];
  String _selectedDenomination = '';
  String _selectedChurchAttendance = '';
  String _selectedRelationshipGoal = '';
  bool _hasChildren = false;
  bool _wantsChildren = false;
  bool _drinks = false;
  bool _smokes = false;
  List<String> _selectedLanguages = [];

  // Options
  final List<String> _denominationOptions = [
    'Catholic',
    'Protestant',
    'Orthodox',
    'Baptist',
    'Methodist',
    'Presbyterian',
    'Lutheran',
    'Pentecostal',
    'Anglican',
    'Non-denominational'
  ];

  final List<String> _churchAttendanceOptions = [
    'Weekly',
    'Monthly',
    'Occasionally',
    'Holidays only',
    'Rarely'
  ];

  final List<String> _interestOptions = [
    'Reading',
    'Traveling',
    'Cooking',
    'Music',
    'Sports',
    'Art',
    'Photography',
    'Hiking',
    'Dancing',
    'Volunteering',
    'Bible Study',
    'Prayer',
    'Worship'
  ];

  final List<String> _languageOptions = [
    'English',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Other'
  ];

  final List<String> _relationshipGoalOptions = [
    'Marriage',
    'Long-term relationship',
    'Friendship first',
    'Casual dating'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupAnimations();
    _loadCurrentProfile();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sectionController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
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
      curve: Curves.easeOut,
    ));

    _sectionFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sectionController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _sectionController.forward();
      }
    });
  }

  void _loadCurrentProfile() {
    // Load current user profile data - in real app this would come from state management
    final currentProfile = MockUsers.sampleProfiles.first;

    _bioController.text = currentProfile.bio;
    _occupationController.text = currentProfile.occupation;
    _educationController.text = currentProfile.education;
    _heightController.text = currentProfile.height;
    _favoriteVerseController.text = currentProfile.favoriteVerse;
    _faithStoryController.text = currentProfile.faithStory;

    _selectedInterests = List.from(currentProfile.interests);
    _selectedDenomination = currentProfile.denomination;
    _selectedChurchAttendance = currentProfile.churchAttendance;
    _selectedRelationshipGoal = currentProfile.relationshipGoal;
    _hasChildren = currentProfile.hasChildren;
    _wantsChildren = currentProfile.wantsChildren;
    _drinks = currentProfile.drinks;
    _smokes = currentProfile.smokes;
    _selectedLanguages = List.from(currentProfile.languages);
  }

  void _saveProfile() {
    HapticFeedback.mediumImpact();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate back
    Navigator.of(context).pop();
  }

  void _closeProfile() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _sectionController.dispose();
    _scrollController.dispose();
    _bioController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    _heightController.dispose();
    _favoriteVerseController.dispose();
    _faithStoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: AnimatedBuilder(
                      animation: _sectionFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _sectionFadeAnimation.value,
                          child: Column(
                            children: [
                              _buildPhotoSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildBasicInfoSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildBioSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildFaithSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildInterestsSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildLifestyleSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildLanguagesSection(),
                              const SizedBox(height: 100), // Bottom padding
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.white, AppColors.offWhite],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _closeProfile,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacing8),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: const Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.loveGradient.createShader(bounds),
                  child: Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your information',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _buildSection(
      title: 'Photos',
      icon: Icons.photo_camera_outlined,
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.lightGray.withOpacity(0.5),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing12),
                    decoration: BoxDecoration(
                      gradient: AppColors.loveGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    'Add Photos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Add up to 6 photos to showcase your personality',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildTextField(
            controller: _occupationController,
            label: 'Occupation',
            hint: 'What do you do for work?',
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTextField(
            controller: _educationController,
            label: 'Education',
            hint: 'Your education background',
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTextField(
            controller: _heightController,
            label: 'Height',
            hint: 'e.g., 5\'8" or 173 cm',
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildDropdown(
            label: 'Relationship Goal',
            value: _selectedRelationshipGoal,
            options: _relationshipGoalOptions,
            onChanged: (value) {
              setState(() {
                _selectedRelationshipGoal = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return _buildSection(
      title: 'About Me',
      icon: Icons.edit_outlined,
      child: Column(
        children: [
          _buildTextField(
            controller: _bioController,
            label: 'Bio',
            hint: 'Tell others about yourself...',
            maxLines: 4,
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_bioController.text.length}/500',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaithSection() {
    return _buildSection(
      title: 'Faith & Beliefs',
      icon: Icons.church_outlined,
      child: Column(
        children: [
          _buildDropdown(
            label: 'Denomination',
            value: _selectedDenomination,
            options: _denominationOptions,
            onChanged: (value) {
              setState(() {
                _selectedDenomination = value ?? '';
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildDropdown(
            label: 'Church Attendance',
            value: _selectedChurchAttendance,
            options: _churchAttendanceOptions,
            onChanged: (value) {
              setState(() {
                _selectedChurchAttendance = value ?? '';
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTextField(
            controller: _favoriteVerseController,
            label: 'Favorite Bible Verse',
            hint: 'Share your favorite verse',
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTextField(
            controller: _faithStoryController,
            label: 'Faith Story',
            hint: 'Share your faith journey...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests & Hobbies',
      icon: Icons.star_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select your interests (up to 10)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: _interestOptions.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 10) {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.loveGradient : null,
                    color: isSelected
                        ? null
                        : AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color:
                          isSelected ? Colors.transparent : AppColors.lightGray,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleSection() {
    return _buildSection(
      title: 'Lifestyle',
      icon: Icons.favorite_outline,
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Has Children',
            value: _hasChildren,
            onChanged: (value) {
              setState(() {
                _hasChildren = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Wants Children',
            value: _wantsChildren,
            onChanged: (value) {
              setState(() {
                _wantsChildren = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Drinks Alcohol',
            value: _drinks,
            onChanged: (value) {
              setState(() {
                _drinks = value;
              });
            },
          ),
          _buildSwitchTile(
            title: 'Smokes',
            value: _smokes,
            onChanged: (value) {
              setState(() {
                _smokes = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return _buildSection(
      title: 'Languages',
      icon: Icons.language_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages you speak',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: _languageOptions.map((language) {
              final isSelected = _selectedLanguages.contains(language);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedLanguages.remove(language);
                    } else {
                      _selectedLanguages.add(language);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.loveGradient : null,
                    color: isSelected
                        ? null
                        : AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color:
                          isSelected ? Colors.transparent : AppColors.lightGray,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    language,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? AppColors.white
                              : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  gradient: AppColors.loveGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Icon(
                  icon,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: label == 'Bio' ? 500 : null,
          onChanged: (value) {
            if (label == 'Bio') {
              setState(() {}); // Refresh character count
            }
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            filled: true,
            fillColor: AppColors.lightGray.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppDimensions.paddingM),
            counterText: label == 'Bio' ? '' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value.isEmpty ? null : value,
              hint: Text(
                'Select $label',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            },
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
            inactiveThumbColor: AppColors.lightGray,
            inactiveTrackColor: AppColors.lightGray.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'Cancel',
              onPressed: _closeProfile,
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Save Changes',
              onPressed: _saveProfile,
              variant: ButtonVariant.gradient,
              size: ButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}
