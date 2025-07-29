import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late List<Animation<double>> _cardAnimations;

  // Mock user data - in real app this would come from user state/BLoC
  final Map<String, dynamic> _currentUser = {
    'firstName': 'Sarah',
    'lastName': 'Johnson',
    'age': 26,
    'location': 'Austin, TX',
    'denomination': 'Non-denominational',
    'occupation': 'Elementary Teacher',
    'bio': 'Elementary school teacher who loves hiking, worship music, and coffee dates. Looking for someone to share life\'s adventures and grow in faith together! 🌟',
    'favoriteVerse': 'Jeremiah 29:11',
    'profileCompletion': 85,
    'totalLikes': 127,
    'totalMatches': 23,
    'profileViews': 89,
    'photoCount': 4,
    'maxPhotos': 6,
    'isVerified': true,
    'isPremium': false,
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    // Setup individual animations for cards
    final cardItems = [
      'stats', 'completion', 'settings1', 'settings2', 'settings3', 'settings4', 'settings5'
    ];
    
    _cardAnimations = List.generate(cardItems.length, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _listController,
        curve: Interval(
          index * 0.1,
          0.4 + (index * 0.1),
          curve: Curves.easeOutBack,
        ),
      ));
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
      _headerController.forward();
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _listController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
            child: _buildContent(),
                  ),
                ],
              ),
          );
        },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.white,
                    AppColors.offWhite,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
      child: Column(
                children: [
                  Row(
        children: [
                      _buildProfileAvatar(),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: _buildProfileInfo(),
                      ),
                      _buildEditButton(),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  _buildVerificationBadge(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return Stack(
      children: [
        Container(
          width: AppDimensions.avatarXL,
          height: AppDimensions.avatarXL,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
              shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 3,
            ),
              boxShadow: [
                BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 48,
            color: AppColors.textSecondary,
            ),
          ),
        if (_currentUser['isVerified'])
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_currentUser['firstName']} ${_currentUser['lastName']}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_currentUser['isPremium'])
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXS,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, AppColors.accentLight],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
            child: Text(
                  'Premium',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          '${_currentUser['age']} • ${_currentUser['location']}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          _currentUser['occupation'],
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to edit profile
        _showComingSoon('Profile editing');
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: AppColors.lightGray.withOpacity(0.7),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.edit,
          color: AppColors.textSecondary,
          size: AppDimensions.iconS,
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.loveGradient.scale(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _currentUser['isVerified'] ? Icons.verified : Icons.pending,
            color: AppColors.primary,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Text(
            _currentUser['isVerified'] 
                ? 'Profile Verified' 
                : 'Verification Pending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Stats
          AnimatedBuilder(
            animation: _cardAnimations[0],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[0].value,
                child: Opacity(
                  opacity: _cardAnimations[0].value.clamp(0.0, 1.0),
                  child: ProfileStatsCard(
                    likes: _currentUser['totalLikes'],
                    matches: _currentUser['totalMatches'],
                    views: _currentUser['profileViews'],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.spacing24),

          // Profile Completion
          AnimatedBuilder(
            animation: _cardAnimations[1],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[1].value,
                child: Opacity(
                  opacity: _cardAnimations[1].value.clamp(0.0, 1.0),
                  child: ProfileCompletionCard(
                    completion: _currentUser['profileCompletion'],
                    photoCount: _currentUser['photoCount'],
                    maxPhotos: _currentUser['maxPhotos'],
                    onCompleteProfile: () {
                      HapticFeedback.lightImpact();
                      _showComingSoon('Profile completion');
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppDimensions.spacing32),

          // Settings Section
          Text(
            AppStrings.settings,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          // Settings Items
          ..._buildSettingsItems(),

          const SizedBox(height: AppDimensions.spacing24),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsItems() {
    final settingsItems = [
      {
        'icon': Icons.person,
        'title': AppStrings.editProfile,
        'subtitle': 'Update your photos, bio, and preferences',
        'color': AppColors.primary,
        'onTap': () => _showComingSoon('Edit profile'),
      },
      {
        'icon': Icons.notifications,
        'title': AppStrings.notificationSettings,
        'subtitle': 'Manage your notification preferences',
        'color': AppColors.secondary,
        'onTap': () => _showComingSoon('Notification settings'),
      },
      {
        'icon': Icons.security,
        'title': AppStrings.privacySettings,
        'subtitle': 'Control who can see your profile',
        'color': AppColors.accent,
        'onTap': () => _showComingSoon('Privacy settings'),
      },
      {
        'icon': Icons.star,
        'title': AppStrings.subscriptionSettings,
        'subtitle': 'Manage your premium subscription',
        'color': AppColors.success,
        'onTap': () => _showComingSoon('Subscription settings'),
      },
      {
        'icon': Icons.help,
        'title': AppStrings.helpSupport,
        'subtitle': 'Get help or contact support',
        'color': AppColors.info,
        'onTap': () => _showComingSoon('Help & support'),
      },
    ];

    return settingsItems.asMap().entries.map((entry) {
      final index = entry.key + 2; // Offset by 2 for stats and completion cards
      final item = entry.value;
      
      return AnimatedBuilder(
        animation: _cardAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _cardAnimations[index].value,
            child: Opacity(
              opacity: _cardAnimations[index].value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                child: SettingsTile(
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  color: item['color'] as Color,
                  onTap: item['onTap'] as VoidCallback,
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
} 