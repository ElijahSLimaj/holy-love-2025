import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../../core/services/image_upload_service.dart';

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
  final _profileRepository = ProfileRepository();

  // Photos
  final int _maxPhotos = 6;
  List<String> _photoUrls = [];
  List<String> _thumbnailUrls = [];
  Map<int, double> _uploadProgress = {};
  bool _isSavingPhotos = false;

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

  // Preferences data
  int _ageRangeMin = 22;
  int _ageRangeMax = 35;
  int _maxDistance = 25;
  String _faithImportance = '';
  List<String> _dealBreakers = [];

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
    'Bi-weekly',
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

  Future<void> _loadCurrentProfile() async {
    try {
      final userId = _profileRepository.currentUserId;
      if (userId == null) return;

      final details = await _profileRepository.getProfileDetails(userId);

      if (details != null) {
        // Handle case-insensitive relationship goal matching
        final rawRelationshipGoal = details.relationshipGoal ?? '';
        _selectedRelationshipGoal = _relationshipGoalOptions.firstWhere(
          (option) => option.toLowerCase() == rawRelationshipGoal.toLowerCase(),
          orElse: () => rawRelationshipGoal,
        );
        _bioController.text = details.bio ?? '';
        _occupationController.text = details.occupation ?? '';
        _educationController.text = details.education ?? '';
        _heightController.text = details.height ?? '';
        _favoriteVerseController.text = details.favoriteBibleVerse ?? '';
        _faithStoryController.text = details.faithStory ?? '';

        _selectedInterests = List.from(details.interests);
        
        // Handle case-insensitive denomination matching
        final rawDenomination = details.denomination ?? '';
        _selectedDenomination = _denominationOptions.firstWhere(
          (option) => option.toLowerCase() == rawDenomination.toLowerCase(),
          orElse: () => rawDenomination,
        );
        
        // Handle case-insensitive church attendance matching with variations
        final rawChurchAttendance = details.churchAttendance ?? '';
        _selectedChurchAttendance = _churchAttendanceOptions.firstWhere(
          (option) => _normalizeString(option) == _normalizeString(rawChurchAttendance),
          orElse: () => rawChurchAttendance,
        );
        _hasChildren = details.hasChildren ?? false;
        _wantsChildren = details.wantsChildren ?? false;
        _drinks = details.drinks ?? false;
        _smokes = details.smokes ?? false;
        _selectedLanguages = List.from(details.languages);

        _photoUrls = List<String>.from(details.photoUrls ?? []);
        _thumbnailUrls = List<String>.from(details.thumbnailUrls ?? []);

        // Load preferences data
        if (details.preferences != null) {
          final prefs = details.preferences!;
          _ageRangeMin = prefs['ageRangeMin'] ?? 22;
          _ageRangeMax = prefs['ageRangeMax'] ?? 35;
          _maxDistance = prefs['maxDistance'] ?? 25;
          _faithImportance = prefs['faithImportance'] ?? '';
          _dealBreakers = List<String>.from(prefs['dealBreakers'] ?? []);
        }

        if (mounted) setState(() {});
      }
    } catch (e) {
      // Fallback: keep defaults if load fails
    }
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
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildPreferencesSection(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimensions.spacing12,
              mainAxisSpacing: AppDimensions.spacing12,
              childAspectRatio: 0.75,
            ),
            itemCount: _maxPhotos,
            itemBuilder: (context, index) {
              final hasPhoto = index < _photoUrls.length;
              return GestureDetector(
                onTap: () => _showPhotoOptions(index, hasPhoto),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: AppColors.border,
                          width: hasPhoto ? 0 : 2,
                          style: hasPhoto ? BorderStyle.none : BorderStyle.solid,
                        ),
                      ),
                      child: hasPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                              child: CachedNetworkImage(
                                imageUrl: _photoUrls[index],
                                fit: BoxFit.cover,
                                placeholder: (c, _) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (c, _, __) => const Icon(Icons.broken_image),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppDimensions.spacing12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: AppDimensions.spacing8),
                                  Text(
                                    index == 0 ? 'Main Photo' : 'Add Photo',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    if (index == 0 && hasPhoto)
                      Positioned(
                        top: AppDimensions.spacing8,
                        left: AppDimensions.spacing8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacing8,
                            vertical: AppDimensions.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 12),
                              const SizedBox(width: AppDimensions.spacing4),
                              Text(
                                'Main',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_uploadProgress[index] != null)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            color: Colors.black.withOpacity(0.7),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    value: _uploadProgress[index],
                                    color: AppColors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacing8),
                                Text(
                                  '${((_uploadProgress[index]!)*100).toInt()}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacing12),
          if (_isSavingPhotos)
            Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Text(
                  'Saving photos...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showPhotoOptions(int index, bool hasPhoto) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.spacing8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              if (hasPhoto && index != 0)
                ListTile(
                  leading: const Icon(Icons.star_outline, color: AppColors.primary),
                  title: const Text('Set as main photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _makeMainPhoto(index);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                title: Text(hasPhoto ? 'Replace photo' : 'Add photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadPhoto(index);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto(index);
                  },
                ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(int index) async {
    try {
      final userId = _profileRepository.currentUserId;
      if (userId == null) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      setState(() {
        _uploadProgress[index] = 0.0;
      });

      final result = await ImageUploadService.uploadProfileImage(
        File(picked.path),
        userId,
        customFileName: 'profile_${index + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        onProgress: (p) {
          setState(() {
            _uploadProgress[index] = p;
          });
        },
      );

      if (result != null) {
        if (index < _photoUrls.length) {
          _photoUrls[index] = result.originalUrl;
          if (index < _thumbnailUrls.length) {
            _thumbnailUrls[index] = result.thumbnailUrl;
          } else {
            _thumbnailUrls.add(result.thumbnailUrl);
          }
        } else {
          _photoUrls.add(result.originalUrl);
          _thumbnailUrls.add(result.thumbnailUrl);
        }
        await _savePhotosToRepo();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to upload photo'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
    } finally {
      setState(() {
        _uploadProgress.removeWhere((key, value) => key >= 0);
      });
    }
  }

  Future<void> _savePhotosToRepo() async {
    try {
      final userId = _profileRepository.currentUserId;
      if (userId == null) return;
      setState(() {
        _isSavingPhotos = true;
      });
      final mainPhotoUrl = _photoUrls.isNotEmpty ? _photoUrls.first : null;
      final mainThumbnailUrl = _thumbnailUrls.isNotEmpty ? _thumbnailUrls.first : null;
      await _profileRepository.savePhotos(
        userId: userId,
        photoUrls: _photoUrls,
        thumbnailUrls: _thumbnailUrls,
        mainPhotoUrl: mainPhotoUrl,
        mainThumbnailUrl: mainThumbnailUrl,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPhotos = false;
        });
      }
    }
  }

  void _makeMainPhoto(int index) async {
    if (index <= 0 || index >= _photoUrls.length) return;
    setState(() {
      final tmpUrl = _photoUrls[0];
      _photoUrls[0] = _photoUrls[index];
      _photoUrls[index] = tmpUrl;
      if (_thumbnailUrls.length == _photoUrls.length) {
        final tmpThumb = _thumbnailUrls[0];
        _thumbnailUrls[0] = _thumbnailUrls[index];
        _thumbnailUrls[index] = tmpThumb;
      }
    });
    await _savePhotosToRepo();
  }

  void _removePhoto(int index) async {
    if (index < 0 || index >= _photoUrls.length) return;
    setState(() {
      _photoUrls.removeAt(index);
      if (index < _thumbnailUrls.length) {
        _thumbnailUrls.removeAt(index);
      }
    });
    await _savePhotosToRepo();
  }

  /// Normalize strings for comparison (lowercase, remove hyphens/spaces)
  String _normalizeString(String str) {
    return str.toLowerCase().replaceAll(RegExp(r'[-\s]'), '');
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

  Widget _buildPreferencesSection() {
    return _buildSection(
      title: 'Matching Preferences',
      icon: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Age Range
          Text(
            'Age Range: $_ageRangeMin - $_ageRangeMax years',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          RangeSlider(
            values: RangeValues(_ageRangeMin.toDouble(), _ageRangeMax.toDouble()),
            min: 18,
            max: 65,
            divisions: 47,
            activeColor: AppColors.primary,
            onChanged: (RangeValues values) {
              setState(() {
                _ageRangeMin = values.start.round();
                _ageRangeMax = values.end.round();
              });
            },
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Max Distance
          Text(
            'Max Distance: ${_maxDistance == 100 ? "Anywhere" : "$_maxDistance miles"}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Slider(
            value: _maxDistance.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: AppColors.accent,
            onChanged: (double value) {
              setState(() {
                _maxDistance = value.round();
              });
            },
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Faith Importance
          _buildDropdown(
            label: 'Faith Compatibility',
            value: _faithImportance,
            options: ['Very Important', 'Important', 'Somewhat Important', 'Open-minded'],
            onChanged: (value) {
              setState(() {
                _faithImportance = value ?? '';
              });
            },
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Deal Breakers
          Text(
            'Deal Breakers',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: ['Smoking', 'Heavy Drinking', 'Different Faith', 'Doesn\'t Want Kids', 'Long Distance', 'Party Lifestyle'].map((dealBreaker) {
              final isSelected = _dealBreakers.contains(dealBreaker.toLowerCase().replaceAll(' ', '_').replaceAll('\'', ''));
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    final key = dealBreaker.toLowerCase().replaceAll(' ', '_').replaceAll('\'', '');
                    if (isSelected) {
                      _dealBreakers.remove(key);
                    } else {
                      _dealBreakers.add(key);
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
                    color: isSelected ? AppColors.error : AppColors.lightGray.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    border: Border.all(
                      color: isSelected ? AppColors.error : AppColors.lightGray,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    dealBreaker,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
}
