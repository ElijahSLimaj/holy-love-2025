import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/presentation/bloc/profile_creation_bloc.dart';

class ProfileStepFaith extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(String, dynamic) onDataChanged;
  final VoidCallback? onStepCompleted;

  const ProfileStepFaith({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    this.onStepCompleted,
  });

  @override
  State<ProfileStepFaith> createState() => ProfileStepFaithState();
}

class ProfileStepFaithState extends State<ProfileStepFaith>
    with TickerProviderStateMixin {
  final _bibleVerseController = TextEditingController();
  final _faithStoryController = TextEditingController();
  final _bibleVerseFocusNode = FocusNode();
  final _faithStoryFocusNode = FocusNode();

  late AnimationController _slideController;
  late AnimationController _cardController;
  late List<Animation<Offset>> _sectionAnimations;
  late List<Animation<double>> _cardAnimations;

  String? _selectedDenomination;
  String? _selectedChurchAttendance;

  final List<Map<String, dynamic>> _denominations = [
    {
      'id': 'catholic',
      'name': 'Catholic',
      'icon': '⛪',
      'description': 'Roman Catholic Church'
    },
    {
      'id': 'protestant',
      'name': 'Protestant',
      'icon': '✝️',
      'description': 'Protestant Churches'
    },
    {
      'id': 'orthodox',
      'name': 'Orthodox',
      'icon': '☦️',
      'description': 'Eastern Orthodox'
    },
    {
      'id': 'baptist',
      'name': 'Baptist',
      'icon': '🏛️',
      'description': 'Baptist Churches'
    },
    {
      'id': 'methodist',
      'name': 'Methodist',
      'icon': '⛪',
      'description': 'Methodist Churches'
    },
    {
      'id': 'pentecostal',
      'name': 'Pentecostal',
      'icon': '🔥',
      'description': 'Pentecostal Churches'
    },
    {
      'id': 'presbyterian',
      'name': 'Presbyterian',
      'icon': '🏛️',
      'description': 'Presbyterian Churches'
    },
    {
      'id': 'non_denominational',
      'name': 'Non-denominational',
      'icon': '❤️',
      'description': 'Non-denominational Christian'
    },
  ];

  final List<Map<String, dynamic>> _attendanceOptions = [
    {'id': 'weekly', 'name': 'Weekly', 'description': 'Every week'},
    {'id': 'biweekly', 'name': 'Bi-weekly', 'description': 'Every other week'},
    {'id': 'monthly', 'name': 'Monthly', 'description': 'Once a month'},
    {
      'id': 'occasionally',
      'name': 'Occasionally',
      'description': 'Few times a year'
    },
    {'id': 'rarely', 'name': 'Rarely', 'description': 'Special occasions'},
  ];

  final List<String> _inspirationalVerses = [
    "For I know the plans I have for you, declares the Lord... - Jeremiah 29:11",
    "Love is patient, love is kind... - 1 Corinthians 13:4",
    "Trust in the Lord with all your heart... - Proverbs 3:5-6",
    "Be strong and courageous... - Joshua 1:9",
    "And we know that in all things God works... - Romans 8:28",
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingData();
    _setupListeners();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create staggered animations for sections
    _sectionAnimations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          index * 0.15,
          0.4 + (index * 0.15),
          curve: Curves.easeOutCubic,
        ),
      ));
    });

    // Create staggered animations for denomination cards
    _cardAnimations = List.generate(_denominations.length, (index) {
      final startTime = (index * 0.05).clamp(0.0, 0.8);
      final endTime = (0.3 + (index * 0.05)).clamp(startTime + 0.1, 1.0);

      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _cardController,
        curve: Interval(
          startTime,
          endTime,
          curve: Curves.easeOutBack,
        ),
      ));
    });
  }

  void _loadExistingData() {
    _selectedDenomination = widget.profileData['denomination'];
    _selectedChurchAttendance = widget.profileData['churchAttendance'];
    _bibleVerseController.text = widget.profileData['favoriteBibleVerse'] ?? '';
    _faithStoryController.text = widget.profileData['faithStory'] ?? '';
  }

  void _setupListeners() {
    _bibleVerseController.addListener(() {
      widget.onDataChanged('favoriteBibleVerse', _bibleVerseController.text);
    });

    _faithStoryController.addListener(() {
      widget.onDataChanged('faithStory', _faithStoryController.text);
    });

    _bibleVerseFocusNode.addListener(() => setState(() {}));
    _faithStoryFocusNode.addListener(() => setState(() {}));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _cardController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    _bibleVerseController.dispose();
    _faithStoryController.dispose();
    _bibleVerseFocusNode.dispose();
    _faithStoryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCreationBloc, ProfileCreationState>(
      listener: (context, state) {
        if (state is ProfileCreationStepCompleted && state.stepName == 'faith') {
          widget.onStepCompleted?.call();
        }
      },
      child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing24),

          // Denomination Section
          _buildDenominationSection(),

          const SizedBox(height: AppDimensions.spacing32),

          // Church Attendance Section
          _buildChurchAttendanceSection(),

          const SizedBox(height: AppDimensions.spacing32),

          // Bible Verse Section
          _buildBibleVerseSection(),

          const SizedBox(height: AppDimensions.spacing32),

          // Faith Story Section
          _buildFaithStorySection(),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
      ),
    );
  }

  Widget _buildDenominationSection() {
    return SlideTransition(
      position: _sectionAnimations[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: const BoxDecoration(
                  gradient: AppColors.loveGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.church,
                  color: AppColors.white,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Your Denomination',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing8),

          Text(
            'Help us connect you with others who share your faith tradition',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: AppDimensions.spacing20),

          // Denomination Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  (constraints.maxWidth - AppDimensions.spacing12) / 2;
              final cardHeight =
                  cardWidth / 2.2; // Slightly taller for better text fit

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDimensions.spacing12,
                  mainAxisSpacing: AppDimensions.spacing12,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                itemCount: _denominations.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _cardAnimations[index],
                    builder: (context, child) {
                      return Transform.scale(
                        scale: (0.8 + (0.2 * _cardAnimations[index].value))
                            .clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: _cardAnimations[index].value.clamp(0.0, 1.0),
                          child: _buildDenominationCard(_denominations[index]),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationCard(Map<String, dynamic> denomination) {
    final isSelected = _selectedDenomination == denomination['id'];

    return GestureDetector(
      onTap: () => _selectDenomination(denomination['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  denomination['icon'],
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: AppDimensions.spacing6),
                Expanded(
                  child: Text(
                    denomination['name'],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 16,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchAttendanceSection() {
    return SlideTransition(
      position: _sectionAnimations[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: AppColors.accent,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Church Attendance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing8),

          Text(
            'How often do you attend church services?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Attendance Options
          Column(
            children: _attendanceOptions.map((option) {
              return _buildAttendanceOption(option);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOption(Map<String, dynamic> option) {
    final isSelected = _selectedChurchAttendance == option['id'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: GestureDetector(
        onTap: () => _selectChurchAttendance(option['id']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withOpacity(0.1)
                : AppColors.lightGray,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.gray,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.white,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      option['description'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBibleVerseSection() {
    return SlideTransition(
      position: _sectionAnimations[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppColors.secondary,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Favorite Bible Verse',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing8),

          Text(
            'Share a verse that inspires or guides you',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Bible Verse Input
          _buildAnimatedTextField(
            controller: _bibleVerseController,
            focusNode: _bibleVerseFocusNode,
            labelText: 'Bible Verse',
            hintText:
                'e.g., "For I know the plans I have for you..." - Jeremiah 29:11',
            maxLines: 3,
          ),

          const SizedBox(height: AppDimensions.spacing12),

          // Inspirational Verses
          Text(
            'Need inspiration? Tap a verse below:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

          const SizedBox(height: AppDimensions.spacing8),

          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: _inspirationalVerses.map((verse) {
              return GestureDetector(
                onTap: () => _selectBibleVerse(verse),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingS,
                    vertical: AppDimensions.paddingXS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    border: Border.all(
                      color: AppColors.secondary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    verse.split(' - ')[1], // Show just the reference
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
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

  Widget _buildFaithStorySection() {
    return SlideTransition(
      position: _sectionAnimations[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppColors.success,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Your Faith Journey',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacing8),

          Text(
            'Share your testimony or how faith plays a role in your life (optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Faith Story Input
          _buildAnimatedTextField(
            controller: _faithStoryController,
            focusNode: _faithStoryFocusNode,
            labelText: 'Your Faith Story',
            hintText:
                'Share how you came to faith, what it means to you, or how it guides your relationships...',
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    int maxLines = 1,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          filled: true,
          fillColor: isFocused ? AppColors.white : AppColors.lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  // Selection methods
  void _selectDenomination(String denominationId) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedDenomination = denominationId;
    });

    widget.onDataChanged('denomination', denominationId);
  }

  void _selectChurchAttendance(String attendanceId) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedChurchAttendance = attendanceId;
    });

    widget.onDataChanged('churchAttendance', attendanceId);
  }

  void _selectBibleVerse(String verse) {
    HapticFeedback.lightImpact();

    _bibleVerseController.text = verse;
    _bibleVerseFocusNode.requestFocus();
  }

  /// Save faith information to database
  Future<void> saveFaithInfo() async {
    // Basic validation - at least denomination should be selected
    if (_selectedDenomination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your denomination'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
        ),
      );
      return;
    }

    context.read<ProfileCreationBloc>().add(
      SaveFaithInfoRequested(
        denomination: _selectedDenomination,
        churchAttendance: _selectedChurchAttendance,
        favoriteBibleVerse: _bibleVerseController.text.isNotEmpty ? _bibleVerseController.text : null,
        faithStory: _faithStoryController.text.isNotEmpty ? _faithStoryController.text : null,
      ),
    );
  }
}
