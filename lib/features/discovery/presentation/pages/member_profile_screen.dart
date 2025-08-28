import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/user_profile.dart';
import '../../../messages/presentation/pages/chat_screen.dart';

class MemberProfileScreen extends StatefulWidget {
  final UserProfile user;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  const MemberProfileScreen({
    super.key,
    required this.user,
    this.onLike,
    this.onPass,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _photoController;
  late AnimationController _actionController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _photoScaleAnimation;
  late Animation<Offset> _actionSlideAnimation;

  late PageController _pageController;
  int _currentPhotoIndex = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _scrollController = ScrollController();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _photoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _actionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _photoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _photoController,
      curve: Curves.easeOutBack,
    ));

    _actionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _actionController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimations() async {
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
      _photoController.forward();
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      _actionController.forward();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _photoController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildPhotoGallery(),
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return SlideTransition(
                            position: _slideAnimation,
                            child: _buildProfileContent(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppDimensions.paddingM,
            left: AppDimensions.paddingL,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textPrimary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _actionSlideAnimation,
              builder: (context, child) {
                return SlideTransition(
                  position: _actionSlideAnimation,
                  child: _buildActionButtons(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.6,
      floating: false,
      pinned: false,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: AnimatedBuilder(
        animation: _photoScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _photoScaleAnimation.value.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusXL),
                  bottomRight: Radius.circular(AppDimensions.radiusXL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(AppDimensions.radiusXL),
                  bottomRight: Radius.circular(AppDimensions.radiusXL),
                ),
                child: Stack(
                  children: [
                    // Photo PageView
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPhotoIndex = index;
                        });
                        HapticFeedback.selectionClick();
                      },
                      itemCount: widget.user.photoUrls.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: widget.user.photoUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.cardBackground,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.cardBackground,
                            child: const Icon(
                              Icons.person,
                              size: 100,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),

                    // Photo indicators
                    if (widget.user.photoUrls.length > 1)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 60,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.user.photoUrls
                              .asMap()
                              .entries
                              .map((entry) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 4,
                              width: _currentPhotoIndex == entry.key ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPhotoIndex == entry.key
                                    ? AppColors.white
                                    : AppColors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                    // Online status
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 80,
                      right: AppDimensions.paddingL,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                          vertical: AppDimensions.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: widget.user.isOnline
                              ? AppColors.success.withOpacity(0.9)
                              : AppColors.textSecondary.withOpacity(0.9),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing8),
                            Text(
                              widget.user.isOnline ? 'Online' : 'Offline',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Gradient overlay at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.shadow.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Basic info overlay
                    Positioned(
                      bottom: AppDimensions.paddingL,
                      left: AppDimensions.paddingL,
                      right: AppDimensions.paddingL,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.user.firstName}, ${widget.user.age}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingM,
                                  vertical: AppDimensions.paddingS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppColors.loveGradient,
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusL),
                                ),
                                child: Text(
                                  widget.user.denomination,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacing8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.white.withOpacity(0.8),
                                size: AppDimensions.iconS,
                              ),
                              const SizedBox(width: AppDimensions.spacing4),
                              Text(
                                '${widget.user.location} • ${widget.user.distanceKm}km away',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.white.withOpacity(0.9),
                                    ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing16),
          _buildBioSection(),
          const SizedBox(height: AppDimensions.spacing24),
          _buildFaithSection(),
          const SizedBox(height: AppDimensions.spacing24),
          _buildBasicInfoSection(),
          const SizedBox(height: AppDimensions.spacing24),
          _buildInterestsSection(),
          const SizedBox(height: AppDimensions.spacing24),
          _buildLifestyleSection(),
          const SizedBox(height: 120), // Space for action buttons
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return _buildSection(
      title: 'About ${widget.user.firstName}',
      icon: Icons.person,
      child: Text(
        widget.user.bio,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _buildFaithSection() {
    return _buildSection(
      title: 'Faith Journey',
      icon: Icons.church,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoTile(
            label: 'Denomination',
            value: widget.user.denomination,
            icon: Icons.account_balance,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          _buildInfoTile(
            label: 'Church Attendance',
            value: widget.user.churchAttendance,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient.scale(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      color: AppColors.primary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Text(
                      'Favorite Verse',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  widget.user.favoriteVerse,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faith Story',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppDimensions.spacing8),
              Text(
                widget.user.faithStory,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      icon: Icons.info,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  label: 'Occupation',
                  value: widget.user.occupation,
                  icon: Icons.work,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: _buildInfoTile(
                  label: 'Education',
                  value: widget.user.education,
                  icon: Icons.school,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  label: 'Height',
                  value: widget.user.height,
                  icon: Icons.height,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: _buildInfoTile(
                  label: 'Languages',
                  value: widget.user.languages.join(', '),
                  icon: Icons.language,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  label: 'Relationship Goal',
                  value: widget.user.relationshipGoal,
                  icon: Icons.favorite,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: _buildInfoTile(
                  label: 'Personality',
                  value: widget.user.personalityType,
                  icon: Icons.psychology,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return _buildSection(
      title: 'Interests & Hobbies',
      icon: Icons.favorite,
      child: Wrap(
        spacing: AppDimensions.spacing8,
        runSpacing: AppDimensions.spacing8,
        children: widget.user.interests.map((interest) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              interest,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLifestyleSection() {
    return _buildSection(
      title: 'Lifestyle',
      icon: Icons.local_activity,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLifestyleTile(
                  label: 'Children',
                  value:
                      widget.user.hasChildren ? 'Has children' : 'No children',
                  icon: Icons.child_care,
                  isPositive: widget.user.hasChildren,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: _buildLifestyleTile(
                  label: 'Wants Children',
                  value: widget.user.wantsChildren ? 'Yes' : 'No',
                  icon: Icons.family_restroom,
                  isPositive: widget.user.wantsChildren,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: _buildLifestyleTile(
                  label: 'Drinking',
                  value: widget.user.drinks ? 'Occasionally' : 'No',
                  icon: Icons.local_bar,
                  isPositive: !widget.user.drinks,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: _buildLifestyleTile(
                  label: 'Smoking',
                  value: widget.user.smokes ? 'Yes' : 'No',
                  icon: Icons.smoking_rooms,
                  isPositive: !widget.user.smokes,
                ),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: AppDimensions.iconS,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        child,
      ],
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleTile({
    required String label,
    required String value,
    required IconData icon,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: isPositive
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isPositive
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isPositive ? AppColors.success : AppColors.error,
                size: AppDimensions.iconS,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPositive ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.paddingL,
        right: AppDimensions.paddingL,
        top: AppDimensions.paddingL,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.paddingL,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick actions row
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Message',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ChatScreen(user: widget.user),
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
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.large,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.loveGradient.scale(0.2),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // TODO: Add to favorites
                  },
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppColors.primary,
                    size: AppDimensions.iconM,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),

          // Main action buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Pass',
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onPass?.call();
                    Navigator.of(context).pop();
                  },
                  variant: ButtonVariant.outline,
                  size: ButtonSize.large,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Like ❤️',
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                    widget.onLike?.call();
                    Navigator.of(context).pop();
                  },
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
