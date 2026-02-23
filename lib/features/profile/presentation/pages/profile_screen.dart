import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/profile_completion_card.dart';
import '../widgets/settings_tile.dart';
import '../../../settings/presentation/pages/notification_settings_screen.dart';
import '../../../settings/presentation/pages/privacy_settings_screen.dart';
import '../../../settings/presentation/pages/help_support_screen.dart';
import 'edit_profile_screen.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/models/profile_data.dart';
import '../../data/models/user_stats.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../subscription/presentation/pages/paywall_screen.dart';
import '../../../subscription/presentation/pages/who_viewed_me_screen.dart';

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

  final StatsRepository _statsRepository = StatsRepository();

  ProfileData? _profileData;
  ProfileDetailsData? _profileDetails;
  UserStats? _userStats;
  bool _isLoading = true;
  StreamSubscription<UserStats?>? _statsSubscription;
  final int maxPhotos = 6;

  final Map<String, dynamic> _staticData = {
    'maxPhotos': 6,
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated) {
        final userId = authState.user.id;
        final profileRepository = context.read<ProfileRepository>();

        final profileData = await profileRepository.getProfile(userId);
        final profileDetails = await profileRepository.getProfileDetails(userId);

        await profileRepository.recalculateCompletion(userId);

        final updatedProfileData = await profileRepository.getProfile(userId);

        _statsSubscription = _statsRepository.streamUserStats(userId).listen((stats) {
          if (mounted) {
            setState(() {
              _userStats = stats;
            });
          }
        });

        if (mounted) {
          setState(() {
            _profileData = updatedProfileData ?? profileData;
            _profileDetails = profileDetails;
            _isLoading = false;
          });

          final finalData = updatedProfileData ?? profileData;
          debugPrint('Profile loaded: ${finalData?.firstName} ${finalData?.lastName}');
          debugPrint('Main photo URL: ${finalData?.mainPhotoUrl}');
          debugPrint('Photo count: ${profileDetails?.photoCount}');
          debugPrint('Profile completion: ${finalData?.profileCompletionPercentage}%');
          debugPrint('Profile complete: ${finalData?.profileComplete}');

          _startAnimations();
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startAnimations();
      }
    }
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
      'stats',
      'completion',
      'settings1',
      'settings2',
      'settings3',
      'settings4',
      'settings5'
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
    _statsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : AnimatedBuilder(
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
                gradient: const LinearGradient(
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
    final mainPhotoUrl = _profileData?.mainPhotoUrl;
    
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
          child: ClipOval(
            child: mainPhotoUrl != null && mainPhotoUrl.isNotEmpty
                ? Image.network(
                    mainPhotoUrl,
                    width: AppDimensions.avatarXL,
                    height: AppDimensions.avatarXL,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.textSecondary,
                      );
                    },
                  )
                : const Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
          ),
        ),
        if ((_profileData?.profileComplete ?? false) && (_userStats?.isVerified ?? false))
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
    // Use real data if available, fallback to defaults
    final firstName = _profileData?.firstName ?? 'User';
    final lastName = _profileData?.lastName ?? '';
    final age = _profileData?.age ?? 0;
    final location = _profileData?.location ?? 'Unknown Location';
    final occupation = _profileDetails?.occupation ?? 'Not specified';
    final isPremium = _userStats?.isPremium ?? false;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                lastName.isNotEmpty ? '$firstName $lastName' : firstName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            if (isPremium)
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
          age > 0 ? '$age • $location' : location,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        if (occupation != 'Not specified') ...[
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            occupation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const EditProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
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
    final isVerified = _userStats?.isVerified ?? false;
    final isProfileComplete = _profileData?.profileComplete ?? false;
    
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
            isProfileComplete && isVerified ? Icons.verified : Icons.pending,
            color: AppColors.primary,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Text(
            isProfileComplete && isVerified
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
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo Gallery
          if (_profileDetails?.photoUrls?.isNotEmpty == true)
            AnimatedBuilder(
              animation: _cardAnimations[0],
              builder: (context, child) {
                return Transform.scale(
                  scale: _cardAnimations[0].value,
                  child: Opacity(
                    opacity: _cardAnimations[0].value.clamp(0.0, 1.0),
                    child: _buildPhotoGallery(),
                  ),
                );
              },
            ),

          if (_profileDetails?.photoUrls?.isNotEmpty == true)
            const SizedBox(height: AppDimensions.spacing24),

          // Profile Stats
          AnimatedBuilder(
            animation: _cardAnimations[0],
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimations[0].value,
                child: Opacity(
                  opacity: _cardAnimations[0].value.clamp(0.0, 1.0),
                  child: ProfileStatsCard(
                    likes: _userStats?.totalLikesReceived ?? 0,
                    matches: _userStats?.totalMatches ?? 0,
                    views: _userStats?.profileViews ?? 0,
                    onViewsTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const WhoViewedMeScreen(),
                        ),
                      );
                    },
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
                    completion: _profileData?.profileCompletionPercentage ?? 0,
                    photoCount: _profileDetails?.photoCount ?? 0,
                    maxPhotos: _staticData['maxPhotos'],
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

          // Preferences Section
          if (_profileDetails?.preferences != null)
            AnimatedBuilder(
              animation: _cardAnimations[2],
              builder: (context, child) {
                return Transform.scale(
                  scale: _cardAnimations[2].value,
                  child: Opacity(
                    opacity: _cardAnimations[2].value.clamp(0.0, 1.0),
                    child: _buildPreferencesCard(),
                  ),
                );
              },
            ),

          if (_profileDetails?.preferences != null)
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
        'onTap': () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const EditProfileScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      },
      {
        'icon': Icons.notifications,
        'title': AppStrings.notificationSettings,
        'subtitle': 'Manage your notification preferences',
        'color': AppColors.secondary,
        'onTap': () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const NotificationSettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      },
      {
        'icon': Icons.security,
        'title': AppStrings.privacySettings,
        'subtitle': 'Control who can see your profile',
        'color': AppColors.accent,
        'onTap': () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PrivacySettingsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
      },
      {
        'icon': Icons.star,
        'title': AppStrings.subscriptionSettings,
        'subtitle': _userStats?.isPremium == true
            ? 'Manage your Pro subscription'
            : 'Upgrade to Holy Love Pro',
        'color': AppColors.accent,
        'onTap': () {
          HapticFeedback.lightImpact();
          if (_userStats?.isPremium == true) {
            _showComingSoon('Subscription management');
          } else {
            PaywallScreen.show(context, PaywallTrigger.profileViews);
          }
        },
      },
      {
        'icon': Icons.help,
        'title': AppStrings.helpSupport,
        'subtitle': 'Get help or contact support',
        'color': AppColors.info,
        'onTap': () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HelpSupportScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
            ),
          );
        },
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

  Widget _buildPreferencesCard() {
    final preferences = _profileDetails?.preferences ?? {};
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                decoration: const BoxDecoration(
                  gradient: AppColors.loveGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.tune,
                  color: AppColors.white,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'My Preferences',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppDimensions.spacing20),
          
          // Age Range
          if (preferences['ageRangeMin'] != null && preferences['ageRangeMax'] != null)
            _buildPreferenceItem(
              icon: Icons.cake,
              label: 'Age Range',
              value: '${preferences['ageRangeMin']} - ${preferences['ageRangeMax']} years',
              color: AppColors.primary,
            ),
          
          // Distance
          if (preferences['maxDistance'] != null)
            _buildPreferenceItem(
              icon: Icons.location_on,
              label: 'Max Distance',
              value: preferences['maxDistance'] == 100 
                  ? 'Anywhere' 
                  : '${preferences['maxDistance']} miles',
              color: AppColors.accent,
            ),
          
          // Faith Importance
          if (preferences['faithImportance'] != null)
            _buildPreferenceItem(
              icon: Icons.favorite,
              label: 'Faith Compatibility',
              value: _formatFaithImportance(preferences['faithImportance']),
              color: AppColors.secondary,
            ),
          
          // Deal Breakers
          if (preferences['dealBreakers'] != null && 
              (preferences['dealBreakers'] as List).isNotEmpty)
            _buildDealBreakersItem(preferences['dealBreakers'] as List<dynamic>),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconS,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacing2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealBreakersItem(List<dynamic> dealBreakers) {
    if (dealBreakers.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing8),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deal Breakers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Wrap(
                  spacing: AppDimensions.spacing8,
                  runSpacing: AppDimensions.spacing4,
                  children: dealBreakers.map((dealBreaker) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing8,
                        vertical: AppDimensions.spacing4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _formatDealBreaker(dealBreaker.toString()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFaithImportance(String faithImportance) {
    switch (faithImportance) {
      case 'very_important':
        return 'Very Important';
      case 'important':
        return 'Important';
      case 'somewhat_important':
        return 'Somewhat Important';
      case 'open_minded':
        return 'Open-minded';
      default:
        return faithImportance;
    }
  }

  String _formatDealBreaker(String dealBreaker) {
    switch (dealBreaker) {
      case 'smoking':
        return 'Smoking';
      case 'drinking':
        return 'Heavy Drinking';
      case 'different_faith':
        return 'Different Faith';
      case 'no_kids':
        return 'Doesn\'t Want Kids';
      case 'long_distance':
        return 'Long Distance';
      case 'party_lifestyle':
        return 'Party Lifestyle';
      default:
        return dealBreaker;
    }
  }

  Widget _buildPhotoGallery() {
    final photoUrls = _profileDetails?.photoUrls ?? [];
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                decoration: const BoxDecoration(
                  gradient: AppColors.loveGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: AppColors.white,
                  size: AppDimensions.iconS,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  'My Photos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Text(
                  '${photoUrls.length}/$maxPhotos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimensions.spacing12,
              mainAxisSpacing: AppDimensions.spacing12,
              childAspectRatio: 0.75,
            ),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _showPhotoViewer(photoUrls, index);
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        child: Image.network(
                          photoUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.lightGray,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.lightGray,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (index == 0)
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
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPhotoViewer(List<String> photoUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: photoUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.network(
                      photoUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
