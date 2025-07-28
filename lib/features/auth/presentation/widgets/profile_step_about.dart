import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/constants/app_dimensions.dart';

class ProfileStepAbout extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(String, dynamic) onDataChanged;

  const ProfileStepAbout({
    super.key,
    required this.profileData,
    required this.onDataChanged,
  });

  @override
  State<ProfileStepAbout> createState() => _ProfileStepAboutState();
}

class _ProfileStepAboutState extends State<ProfileStepAbout>
    with TickerProviderStateMixin {
  final _bioController = TextEditingController();
  final _bioFocusNode = FocusNode();
  
  late AnimationController _slideController;
  late AnimationController _chipController;
  late List<Animation<Offset>> _sectionAnimations;
  late List<Animation<double>> _chipAnimations;
  
  List<String> _selectedInterests = [];
  String? _selectedRelationshipGoal;
  
  final List<Map<String, dynamic>> _interests = [
    {'id': 'worship', 'name': 'Worship Music', 'icon': '🎵', 'category': 'faith'},
    {'id': 'bible_study', 'name': 'Bible Study', 'icon': '📖', 'category': 'faith'},
    {'id': 'prayer', 'name': 'Prayer', 'icon': '🙏', 'category': 'faith'},
    {'id': 'volunteering', 'name': 'Volunteering', 'icon': '🤝', 'category': 'faith'},
    {'id': 'missions', 'name': 'Missions', 'icon': '🌍', 'category': 'faith'},
    {'id': 'youth_ministry', 'name': 'Youth Ministry', 'icon': '👥', 'category': 'faith'},
    
    {'id': 'reading', 'name': 'Reading', 'icon': '📚', 'category': 'hobbies'},
    {'id': 'cooking', 'name': 'Cooking', 'icon': '👨‍🍳', 'category': 'hobbies'},
    {'id': 'hiking', 'name': 'Hiking', 'icon': '🥾', 'category': 'hobbies'},
    {'id': 'photography', 'name': 'Photography', 'icon': '📸', 'category': 'hobbies'},
    {'id': 'gardening', 'name': 'Gardening', 'icon': '🌱', 'category': 'hobbies'},
    {'id': 'art', 'name': 'Art & Crafts', 'icon': '🎨', 'category': 'hobbies'},
    
    {'id': 'fitness', 'name': 'Fitness', 'icon': '💪', 'category': 'lifestyle'},
    {'id': 'travel', 'name': 'Travel', 'icon': '✈️', 'category': 'lifestyle'},
    {'id': 'music', 'name': 'Music', 'icon': '🎸', 'category': 'lifestyle'},
    {'id': 'movies', 'name': 'Movies', 'icon': '🎬', 'category': 'lifestyle'},
    {'id': 'sports', 'name': 'Sports', 'icon': '⚽', 'category': 'lifestyle'},
    {'id': 'board_games', 'name': 'Board Games', 'icon': '🎲', 'category': 'lifestyle'},
  ];
  
  final List<Map<String, dynamic>> _relationshipGoals = [
    {'id': 'marriage', 'name': 'Marriage', 'description': 'Looking for a life partner', 'icon': '💒'},
    {'id': 'serious_dating', 'name': 'Serious Dating', 'description': 'Open to long-term relationship', 'icon': '💕'},
    {'id': 'getting_to_know', 'name': 'Getting to Know', 'description': 'Taking things slow', 'icon': '🤝'},
    {'id': 'friendship_first', 'name': 'Friendship First', 'description': 'Building strong foundation', 'icon': '👫'},
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _chipController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Create staggered animations for sections
    _sectionAnimations = List.generate(3, (index) {
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          index * 0.2,
          0.4 + (index * 0.2),
          curve: Curves.easeOutCubic,
        ),
      ));
    });
    
    // Create staggered animations for interest chips
    _chipAnimations = List.generate(_interests.length, (index) {
      final startTime = (index * 0.03).clamp(0.0, 0.7);
      final endTime = (0.3 + (index * 0.03)).clamp(startTime + 0.1, 1.0);
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _chipController,
        curve: Interval(
          startTime,
          endTime,
          curve: Curves.easeOutBack,
        ),
      ));
    });
  }
  
  void _loadExistingData() {
    _bioController.text = widget.profileData['bio'] ?? '';
    _selectedInterests = List<String>.from(widget.profileData['interests'] ?? []);
    _selectedRelationshipGoal = widget.profileData['relationshipGoal'];
  }
  
  void _setupListeners() {
    _bioController.addListener(() {
      widget.onDataChanged('bio', _bioController.text);
    });
    
    _bioFocusNode.addListener(() => setState(() {}));
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) _chipController.forward();
    }
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    _chipController.dispose();
    _bioController.dispose();
    _bioFocusNode.dispose();
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
          
          // Bio Section
          _buildBioSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Interests Section
          _buildInterestsSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Relationship Goals Section
          _buildRelationshipGoalsSection(),
          
          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }
  
  Widget _buildBioSection() {
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
                  Icons.edit,
                  color: AppColors.white,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Tell Your Story',
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
            'Share what makes you unique and what you\'re looking for',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Bio Input
          _buildAnimatedTextField(
            controller: _bioController,
            focusNode: _bioFocusNode,
            labelText: 'About Me',
            hintText: 'Tell others about your personality, hobbies, and what you\'re passionate about. Share what makes you laugh and what you value in relationships...',
            maxLines: 6,
          ),
          
          const SizedBox(height: AppDimensions.spacing8),
          
          // Character count
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_bioController.text.length}/500',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _bioController.text.length > 500 
                    ? AppColors.error 
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInterestsSection() {
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
                  Icons.favorite,
                  color: AppColors.accent,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Your Interests',
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
            'Select what you enjoy doing (choose up to 8)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Interest Categories
          _buildInterestCategory('Faith & Ministry', 'faith'),
          const SizedBox(height: AppDimensions.spacing20),
          _buildInterestCategory('Hobbies', 'hobbies'),
          const SizedBox(height: AppDimensions.spacing20),
          _buildInterestCategory('Lifestyle', 'lifestyle'),
        ],
      ),
    );
  }
  
  Widget _buildInterestCategory(String title, String category) {
    final categoryInterests = _interests.where((i) => i['category'] == category).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: categoryInterests.map((interest) {
            final index = _interests.indexOf(interest);
            return AnimatedBuilder(
              animation: _chipAnimations[index],
              builder: (context, child) {
                return Transform.scale(
                  scale: _chipAnimations[index].value.clamp(0.0, 1.0),
                  child: Opacity(
                    opacity: _chipAnimations[index].value.clamp(0.0, 1.0),
                    child: _buildInterestChip(interest),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildInterestChip(Map<String, dynamic> interest) {
    final isSelected = _selectedInterests.contains(interest['id']);
    final canSelect = _selectedInterests.length < 8 || isSelected;
    
    return GestureDetector(
      onTap: canSelect ? () => _toggleInterest(interest['id']) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary 
              : canSelect 
                  ? AppColors.white 
                  : AppColors.lightGray,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : canSelect 
                    ? AppColors.border 
                    : AppColors.gray,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interest['icon'],
              style: TextStyle(
                fontSize: 16,
                color: canSelect ? null : AppColors.gray,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing6),
            Text(
              interest['name'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected 
                    ? AppColors.white 
                    : canSelect 
                        ? AppColors.textPrimary 
                        : AppColors.gray,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppDimensions.spacing4),
              const Icon(
                Icons.check,
                color: AppColors.white,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRelationshipGoalsSection() {
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
                  Icons.favorite_border,
                  color: AppColors.secondary,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'Relationship Goals',
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
            'What are you hoping to find on Holy Love?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Relationship Goal Cards
          Column(
            children: _relationshipGoals.map((goal) {
              return _buildRelationshipGoalCard(goal);
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRelationshipGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedRelationshipGoal == goal['id'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      child: GestureDetector(
        onTap: () => _selectRelationshipGoal(goal['id']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.paddingL),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.secondary.withOpacity(0.2) 
                      : AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    goal['icon'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected ? AppColors.secondary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      goal['description'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.secondary,
                  size: 24,
                ),
            ],
          ),
        ),
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
        maxLength: maxLines > 1 ? 500 : null,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          filled: true,
          fillColor: isFocused 
              ? AppColors.white 
              : AppColors.lightGray,
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
          counterText: '', // Hide the default counter
        ),
      ),
    );
  }
  
  // Selection methods
  void _toggleInterest(String interestId) {
    HapticFeedback.lightImpact();
    
    setState(() {
      if (_selectedInterests.contains(interestId)) {
        _selectedInterests.remove(interestId);
      } else if (_selectedInterests.length < 8) {
        _selectedInterests.add(interestId);
      }
    });
    
    widget.onDataChanged('interests', _selectedInterests);
  }
  
  void _selectRelationshipGoal(String goalId) {
    HapticFeedback.lightImpact();
    
    setState(() {
      _selectedRelationshipGoal = goalId;
    });
    
    widget.onDataChanged('relationshipGoal', goalId);
  }
} 