import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/user_profile.dart';
import '../../data/mock_users.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/swipeable_card_stack.dart';
import '../../../../shared/widgets/custom_button.dart';

enum ViewMode { list, swipe }

class DiscoveryScreen extends StatefulWidget {
  final ViewMode viewMode;
  
  const DiscoveryScreen({
    super.key,
    required this.viewMode,
  });

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  late List<UserProfile> _profiles;
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final Set<String> _likedProfiles = {};
  final Set<String> _passedProfiles = {};
  final GlobalKey<SwipeableCardStackState> _cardStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _profiles = MockUsers.getDiscoveryProfiles();
    
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _listAnimationController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart list animations when switching to list view
    if (oldWidget.viewMode != widget.viewMode && widget.viewMode == ViewMode.list) {
      _listAnimationController.reset();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _listAnimationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLike(UserProfile profile) {
    HapticFeedback.lightImpact();
    setState(() {
      _likedProfiles.add(profile.id);
    });
    // TODO: Implement like logic
  }

  void _onPass(UserProfile profile) {
    HapticFeedback.selectionClick();
    setState(() {
      _passedProfiles.add(profile.id);
    });
    // TODO: Implement pass logic
  }

  void _onProfileTap(UserProfile profile) {
    HapticFeedback.selectionClick();
    // TODO: Navigate to detailed profile view
  }

  void _onStackEmpty() {
    // TODO: Load more profiles or show empty state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: widget.viewMode == ViewMode.list 
                  ? _buildProfileList()
                  : _buildSwipeView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingS),
                        decoration: BoxDecoration(
                          gradient: AppColors.loveGradient,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.textOnPrimary,
                          size: AppDimensions.iconM,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.discover,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Find your God-centered match',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing16),
                  Container(
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
                          Icons.auto_awesome,
                          color: AppColors.primary,
                          size: AppDimensions.iconS,
                        ),
                        const SizedBox(width: AppDimensions.spacing8),
                        Text(
                          '${_profiles.length} faithful hearts nearby',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
      },
    );
  }



  Widget _buildSwipeView() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          Expanded(
            child: SwipeableCardStack(
              key: _cardStackKey,
              profiles: _profiles,
              onLike: _onLike,
              onPass: _onPass,
              onCardTap: _onProfileTap,
              onStackEmpty: _onStackEmpty,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.close,
          color: AppColors.error,
          onTap: () {
            _cardStackKey.currentState?.swipeLeft();
          },
        ),
        _buildActionButton(
          icon: Icons.tune,
          color: AppColors.accent,
          onTap: () {
            // TODO: Open filters/preferences
          },
        ),
        _buildActionButton(
          icon: Icons.favorite,
          color: AppColors.secondary,
          onTap: () {
            _cardStackKey.currentState?.swipeRight();
          },
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildProfileList() {
    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
          itemCount: _profiles.length,
          itemBuilder: (context, index) {
            final profile = _profiles[index];
            final animationDelay = index * 0.1;
            final isLiked = _likedProfiles.contains(profile.id);
            final isPassed = _passedProfiles.contains(profile.id);
            
            return _buildAnimatedProfileCard(
              profile, 
              index, 
              animationDelay,
              isLiked,
              isPassed,
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedProfileCard(
    UserProfile profile, 
    int index, 
    double delay,
    bool isLiked,
    bool isPassed,
  ) {
    final animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Interval(
        delay.clamp(0.0, 1.0),
        (delay + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOutBack,
      ),
    ));

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Interval(
        delay.clamp(0.0, 1.0),
        (delay + 0.3).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    ));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: Transform.scale(
              scale: animation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spacing24),
                child: _buildProfileCard(profile, isLiked, isPassed),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(UserProfile profile, bool isLiked, bool isPassed) {
    return GestureDetector(
      onTap: () => _onProfileTap(profile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: isLiked 
                ? AppColors.success.withOpacity(0.3)
                : isPassed
                    ? AppColors.error.withOpacity(0.3)
                    : AppColors.border,
            width: isLiked || isPassed ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoSection(profile),
            _buildInfoSection(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(UserProfile profile) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Stack(
        children: [
          // Photo placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightGray,
                  AppColors.lightGray.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusXL),
                topRight: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 80,
              color: AppColors.textSecondary,
            ),
          ),
          // Gradient overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusXL),
                  topRight: Radius.circular(AppDimensions.radiusXL),
                ),
              ),
            ),
          ),
          // Basic info overlay
          Positioned(
            bottom: AppDimensions.paddingM,
            left: AppDimensions.paddingM,
            right: AppDimensions.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${profile.fullName}, ${profile.age}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isOnline)
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.paddingXS),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: AppDimensions.iconS,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacing4),
                    Expanded(
                      child: Text(
                        profile.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildInfoSection(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bio.isNotEmpty) ...[
            Text(
              profile.bio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppDimensions.spacing16),
          ],
          
          // Faith info
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient.scale(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.church,
                      color: AppColors.primary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Text(
                        profile.denomination,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (profile.churchAttendance.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    'Attends church ${profile.churchAttendance.toLowerCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing16),
          
          // Interests
          if (profile.interests.isNotEmpty) ...[
            Wrap(
              spacing: AppDimensions.spacing8,
              runSpacing: AppDimensions.spacing8,
              children: profile.interests.take(4).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingM,
                    vertical: AppDimensions.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    interest,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }


} 