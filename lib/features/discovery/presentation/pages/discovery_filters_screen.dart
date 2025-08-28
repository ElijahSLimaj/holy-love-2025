import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';

class FilterCriteria {
  final RangeValues ageRange;
  final double maxDistance;
  final RangeValues heightRange;
  final List<String> selectedDenominations;
  final List<String> selectedChurchAttendance;
  final List<String> selectedInterests;
  final List<String> selectedEducation;
  final List<String> selectedOccupations;
  final List<String> selectedLanguages;
  final bool? hasChildren;
  final bool? wantsChildren;
  final bool? drinks;
  final bool? smokes;
  final bool? onlineOnly;
  final List<String> selectedRelationshipGoals;

  const FilterCriteria({
    this.ageRange = const RangeValues(18, 65),
    this.maxDistance = 50.0,
    this.heightRange = const RangeValues(150, 200),
    this.selectedDenominations = const [],
    this.selectedChurchAttendance = const [],
    this.selectedInterests = const [],
    this.selectedEducation = const [],
    this.selectedOccupations = const [],
    this.selectedLanguages = const [],
    this.hasChildren,
    this.wantsChildren,
    this.drinks,
    this.smokes,
    this.onlineOnly,
    this.selectedRelationshipGoals = const [],
  });

  FilterCriteria copyWith({
    RangeValues? ageRange,
    double? maxDistance,
    RangeValues? heightRange,
    List<String>? selectedDenominations,
    List<String>? selectedChurchAttendance,
    List<String>? selectedInterests,
    List<String>? selectedEducation,
    List<String>? selectedOccupations,
    List<String>? selectedLanguages,
    bool? hasChildren,
    bool? wantsChildren,
    bool? drinks,
    bool? smokes,
    bool? onlineOnly,
    List<String>? selectedRelationshipGoals,
  }) {
    return FilterCriteria(
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      heightRange: heightRange ?? this.heightRange,
      selectedDenominations:
          selectedDenominations ?? this.selectedDenominations,
      selectedChurchAttendance:
          selectedChurchAttendance ?? this.selectedChurchAttendance,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      selectedEducation: selectedEducation ?? this.selectedEducation,
      selectedOccupations: selectedOccupations ?? this.selectedOccupations,
      selectedLanguages: selectedLanguages ?? this.selectedLanguages,
      hasChildren: hasChildren ?? this.hasChildren,
      wantsChildren: wantsChildren ?? this.wantsChildren,
      drinks: drinks ?? this.drinks,
      smokes: smokes ?? this.smokes,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      selectedRelationshipGoals:
          selectedRelationshipGoals ?? this.selectedRelationshipGoals,
    );
  }
}

class DiscoveryFiltersScreen extends StatefulWidget {
  final FilterCriteria? initialFilters;

  const DiscoveryFiltersScreen({
    super.key,
    this.initialFilters,
  });

  @override
  State<DiscoveryFiltersScreen> createState() => _DiscoveryFiltersScreenState();
}

class _DiscoveryFiltersScreenState extends State<DiscoveryFiltersScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _sectionController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sectionFadeAnimation;

  late ScrollController _scrollController;
  late FilterCriteria _filters;

  // Filter options
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

  final List<String> _educationOptions = [
    'High School',
    'Some College',
    'Bachelor\'s',
    'Master\'s',
    'Doctorate',
    'Trade School'
  ];

  final List<String> _occupationOptions = [
    'Healthcare',
    'Education',
    'Technology',
    'Business',
    'Ministry',
    'Arts',
    'Engineering',
    'Social Work',
    'Non-profit',
    'Government',
    'Other'
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
    _filters = widget.initialFilters ?? const FilterCriteria();
    _scrollController = ScrollController();
    _setupAnimations();
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

  void _applyFilters() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(_filters);
  }

  void _resetFilters() {
    HapticFeedback.lightImpact();
    setState(() {
      _filters = const FilterCriteria();
    });
  }

  void _closeFilters() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _sectionController.dispose();
    _scrollController.dispose();
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
                              _buildDemographicsSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildFaithSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildLifestyleSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildInterestsSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildEducationCareerSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildLanguagesSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildRelationshipSection(),
                              const SizedBox(height: AppDimensions.spacing32),
                              _buildActivitySection(),
                              const SizedBox(
                                  height: 100), // Bottom padding for buttons
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
            onTap: _closeFilters,
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
                    'Discovery Filters',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find your perfect match',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _resetFilters,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.spacing8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Text(
                'Reset',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection() {
    return _buildSection(
      title: 'Demographics',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildRangeSlider(
            title: 'Age Range',
            values: _filters.ageRange,
            min: 18,
            max: 65,
            divisions: 47,
            onChanged: (values) {
              setState(() {
                _filters = _filters.copyWith(ageRange: values);
              });
            },
            formatLabel: (value) => '${value.round()}',
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildSlider(
            title: 'Maximum Distance',
            value: _filters.maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(maxDistance: value);
              });
            },
            formatLabel: (value) => '${value.round()} km',
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildRangeSlider(
            title: 'Height Range',
            values: _filters.heightRange,
            min: 140,
            max: 220,
            divisions: 80,
            onChanged: (values) {
              setState(() {
                _filters = _filters.copyWith(heightRange: values);
              });
            },
            formatLabel: (value) => '${value.round()} cm',
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
          _buildMultiSelectChips(
            title: 'Denomination',
            options: _denominationOptions,
            selectedOptions: _filters.selectedDenominations,
            onSelectionChanged: (selected) {
              setState(() {
                _filters = _filters.copyWith(selectedDenominations: selected);
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildMultiSelectChips(
            title: 'Church Attendance',
            options: _churchAttendanceOptions,
            selectedOptions: _filters.selectedChurchAttendance,
            onSelectionChanged: (selected) {
              setState(() {
                _filters =
                    _filters.copyWith(selectedChurchAttendance: selected);
              });
            },
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
          _buildTriStateToggle(
            title: 'Has Children',
            value: _filters.hasChildren,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(hasChildren: value);
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTriStateToggle(
            title: 'Wants Children',
            value: _filters.wantsChildren,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(wantsChildren: value);
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTriStateToggle(
            title: 'Drinks Alcohol',
            value: _filters.drinks,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(drinks: value);
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTriStateToggle(
            title: 'Smokes',
            value: _filters.smokes,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(smokes: value);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests & Hobbies',
      icon: Icons.star_outline,
      child: _buildMultiSelectChips(
        title: 'Select interests you\'d like to share',
        options: _interestOptions,
        selectedOptions: _filters.selectedInterests,
        onSelectionChanged: (selected) {
          setState(() {
            _filters = _filters.copyWith(selectedInterests: selected);
          });
        },
      ),
    );
  }

  Widget _buildEducationCareerSection() {
    return _buildSection(
      title: 'Education & Career',
      icon: Icons.school_outlined,
      child: Column(
        children: [
          _buildMultiSelectChips(
            title: 'Education Level',
            options: _educationOptions,
            selectedOptions: _filters.selectedEducation,
            onSelectionChanged: (selected) {
              setState(() {
                _filters = _filters.copyWith(selectedEducation: selected);
              });
            },
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildMultiSelectChips(
            title: 'Industry/Field',
            options: _occupationOptions,
            selectedOptions: _filters.selectedOccupations,
            onSelectionChanged: (selected) {
              setState(() {
                _filters = _filters.copyWith(selectedOccupations: selected);
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
      child: _buildMultiSelectChips(
        title: 'Languages spoken',
        options: _languageOptions,
        selectedOptions: _filters.selectedLanguages,
        onSelectionChanged: (selected) {
          setState(() {
            _filters = _filters.copyWith(selectedLanguages: selected);
          });
        },
      ),
    );
  }

  Widget _buildRelationshipSection() {
    return _buildSection(
      title: 'Relationship Goals',
      icon: Icons.favorite_border,
      child: _buildMultiSelectChips(
        title: 'Looking for',
        options: _relationshipGoalOptions,
        selectedOptions: _filters.selectedRelationshipGoals,
        onSelectionChanged: (selected) {
          setState(() {
            _filters = _filters.copyWith(selectedRelationshipGoals: selected);
          });
        },
      ),
    );
  }

  Widget _buildActivitySection() {
    return _buildSection(
      title: 'Activity Status',
      icon: Icons.online_prediction_outlined,
      child: _buildTriStateToggle(
        title: 'Show only online users',
        value: _filters.onlineOnly,
        onChanged: (value) {
          setState(() {
            _filters = _filters.copyWith(onlineOnly: value);
          });
        },
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

  Widget _buildRangeSlider({
    required String title,
    required RangeValues values,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<RangeValues> onChanged,
    required String Function(double) formatLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              '${formatLabel(values.start)} - ${formatLabel(values.end)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.lightGray,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) formatLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
            ),
            Text(
              formatLabel(value),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.lightGray,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips({
    required String title,
    required List<String> options,
    required List<String> selectedOptions,
    required ValueChanged<List<String>> onSelectionChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppDimensions.spacing16),
        Wrap(
          spacing: AppDimensions.spacing12,
          runSpacing: AppDimensions.spacing12,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                final newSelection = List<String>.from(selectedOptions);
                if (isSelected) {
                  newSelection.remove(option);
                } else {
                  newSelection.add(option);
                }
                onSelectionChanged(newSelection);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.spacing12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.loveGradient : null,
                  color:
                      isSelected ? null : AppColors.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color:
                        isSelected ? Colors.transparent : AppColors.lightGray,
                    width: 1,
                  ),
                ),
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildTriStateToggle({
    required String title,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildToggleOption('Any', value == null, () => onChanged(null)),
              const SizedBox(width: AppDimensions.spacing8),
              _buildToggleOption('Yes', value == true, () => onChanged(true)),
              const SizedBox(width: AppDimensions.spacing8),
              _buildToggleOption('No', value == false, () => onChanged(false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.loveGradient : null,
          color: isSelected ? null : AppColors.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.lightGray,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
        ),
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
              text: 'Clear All',
              onPressed: _resetFilters,
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Apply Filters',
              onPressed: _applyFilters,
              variant: ButtonVariant.gradient,
              size: ButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }
}
