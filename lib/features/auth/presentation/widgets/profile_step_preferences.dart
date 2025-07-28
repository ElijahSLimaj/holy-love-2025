import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/constants/app_dimensions.dart';

class ProfileStepPreferences extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(String, dynamic) onDataChanged;

  const ProfileStepPreferences({
    super.key,
    required this.profileData,
    required this.onDataChanged,
  });

  @override
  State<ProfileStepPreferences> createState() => _ProfileStepPreferencesState();
}

class _ProfileStepPreferencesState extends State<ProfileStepPreferences>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _sliderController;
  late List<Animation<Offset>> _sectionAnimations;
  late Animation<double> _sliderAnimation;
  
  RangeValues _ageRange = const RangeValues(22, 35);
  double _maxDistance = 25.0;
  String? _selectedFaithImportance;
  List<String> _selectedDealBreakers = [];
  
  final List<Map<String, dynamic>> _faithImportanceOptions = [
    {'id': 'very_important', 'name': 'Very Important', 'description': 'Faith is central to my life', 'icon': '⭐'},
    {'id': 'important', 'name': 'Important', 'description': 'Faith matters to me', 'icon': '✨'},
    {'id': 'somewhat_important', 'name': 'Somewhat Important', 'description': 'Faith has some importance', 'icon': '💫'},
    {'id': 'open_minded', 'name': 'Open-minded', 'description': 'Respectful of all beliefs', 'icon': '🤝'},
  ];
  
  final List<Map<String, dynamic>> _dealBreakers = [
    {'id': 'smoking', 'name': 'Smoking', 'icon': '🚭'},
    {'id': 'drinking', 'name': 'Heavy Drinking', 'icon': '🍺'},
    {'id': 'different_faith', 'name': 'Different Faith', 'icon': '⛪'},
    {'id': 'no_kids', 'name': 'Doesn\'t Want Kids', 'icon': '👶'},
    {'id': 'long_distance', 'name': 'Long Distance', 'icon': '📍'},
    {'id': 'party_lifestyle', 'name': 'Party Lifestyle', 'icon': '🎉'},
  ];
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingData();
    _startAnimations();
  }
  
  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _sliderController = AnimationController(
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
    
    _sliderAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sliderController,
      curve: Curves.easeOutBack,
    ));
  }
  
  void _loadExistingData() {
    if (widget.profileData['ageRange'] != null) {
      final range = widget.profileData['ageRange'] as Map<String, dynamic>;
      _ageRange = RangeValues(
        range['min']?.toDouble() ?? 22.0,
        range['max']?.toDouble() ?? 35.0,
      );
    }
    
    _maxDistance = widget.profileData['maxDistance']?.toDouble() ?? 25.0;
    _selectedFaithImportance = widget.profileData['faithImportance'];
    _selectedDealBreakers = List<String>.from(widget.profileData['dealBreakers'] ?? []);
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _sliderController.forward();
    }
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _sliderController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing24),
          
          // Age Range Section
          _buildAgeRangeSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Distance Section
          _buildDistanceSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Faith Importance Section
          _buildFaithImportanceSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Deal Breakers Section
          _buildDealBreakersSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
  
  Widget _buildAgeRangeSection() {
    return SlideTransition(
      position: _sectionAnimations[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  gradient: AppColors.loveGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cake,
                  color: AppColors.white,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Age Range',
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
            'What age range are you interested in?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing24),
          
          // Age Range Display
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAgeDisplay('Min Age', _ageRange.start.round()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingM,
                        vertical: AppDimensions.paddingS,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.loveGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      ),
                      child: Text(
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildAgeDisplay('Max Age', _ageRange.end.round()),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.spacing20),
                
                // Age Range Slider
                AnimatedBuilder(
                  animation: _sliderAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sliderAnimation.value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * _sliderAnimation.value),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.lightGray,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 12),
                            trackHeight: 6,
                          ),
                          child: RangeSlider(
                            values: _ageRange,
                            min: 18,
                            max: 65,
                            divisions: 47,
                            onChanged: _updateAgeRange,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAgeDisplay(String label, int age) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          age.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDistanceSection() {
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
                  Icons.location_on,
                  color: AppColors.accent,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Maximum Distance',
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
            'How far are you willing to travel for a match?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing24),
          
          // Distance Display
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _maxDistance == 100 ? 'Anywhere' : '${_maxDistance.round()} miles',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                const SizedBox(height: AppDimensions.spacing16),
                
                // Distance Slider
                AnimatedBuilder(
                  animation: _sliderAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _sliderAnimation.value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * _sliderAnimation.value),
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.accent,
                            inactiveTrackColor: AppColors.lightGray,
                            thumbColor: AppColors.accent,
                            overlayColor: AppColors.accent.withOpacity(0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: _maxDistance,
                            min: 5,
                            max: 100,
                            divisions: 19,
                            onChanged: _updateMaxDistance,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '5 miles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      'Anywhere',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFaithImportanceSection() {
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
                  Icons.favorite,
                  color: AppColors.secondary,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Faith Compatibility',
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
            'How important is it that your match shares your faith?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Faith Importance Options
          Column(
            children: _faithImportanceOptions.map((option) {
              return _buildFaithImportanceOption(option);
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFaithImportanceOption(Map<String, dynamic> option) {
    final isSelected = _selectedFaithImportance == option['id'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
      child: GestureDetector(
        onTap: () => _selectFaithImportance(option['id']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondary.withOpacity(0.1) : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.secondary.withOpacity(0.2) 
                      : AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    option['icon'],
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option['name'],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected ? AppColors.secondary : AppColors.textPrimary,
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
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDealBreakersSection() {
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
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block,
                  color: AppColors.error,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Deal Breakers',
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
            'Select any absolute deal breakers (optional)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Deal Breakers Grid
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: _dealBreakers.map((dealBreaker) {
              return _buildDealBreakerChip(dealBreaker);
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDealBreakerChip(Map<String, dynamic> dealBreaker) {
    final isSelected = _selectedDealBreakers.contains(dealBreaker['id']);
    
    return GestureDetector(
      onTap: () => _toggleDealBreaker(dealBreaker['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.error : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.error.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dealBreaker['icon'],
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: AppDimensions.spacing6),
            Text(
              dealBreaker['name'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppDimensions.spacing4),
              const Icon(
                Icons.close,
                color: AppColors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Update methods
  void _updateAgeRange(RangeValues newRange) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _ageRange = newRange;
    });
    
    widget.onDataChanged('ageRange', {
      'min': newRange.start.round(),
      'max': newRange.end.round(),
    });
  }
  
  void _updateMaxDistance(double newDistance) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _maxDistance = newDistance;
    });
    
    widget.onDataChanged('maxDistance', newDistance.round());
  }
  
  void _selectFaithImportance(String importanceId) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _selectedFaithImportance = importanceId;
    });
    
    widget.onDataChanged('faithImportance', importanceId);
  }
  
  void _toggleDealBreaker(String dealBreakerId) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_selectedDealBreakers.contains(dealBreakerId)) {
        _selectedDealBreakers.remove(dealBreakerId);
      } else {
        _selectedDealBreakers.add(dealBreakerId);
      }
    });
    
    widget.onDataChanged('dealBreakers', _selectedDealBreakers);
  }
} 