import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/models/user_profile.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final bool showActions;
  final double? height;
  final double? width;

  const ProfileCard({
    super.key,
    required this.profile,
    this.onTap,
    this.onLike,
    this.onPass,
    this.showActions = false,
    this.height,
    this.width,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _fadeController.forward();
      _scaleController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: _buildCard(),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: widget.height ?? 600,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          child: Stack(
            children: [
              _buildPhotoSection(),
              _buildGradientOverlay(),
              _buildPhotoIndicators(),
              _buildProfileInfo(),
              if (widget.showActions) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      color: AppColors.lightGray,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              widget.profile.firstName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    return const SizedBox.shrink();
  }

  Widget _buildProfileInfo() {
    return Positioned(
      bottom: widget.showActions ? 80 : AppDimensions.paddingL,
      left: AppDimensions.paddingL,
      right: AppDimensions.paddingL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNameAndAge(),
          const SizedBox(height: AppDimensions.spacing8),
          _buildLocationAndDistance(),
          const SizedBox(height: AppDimensions.spacing12),
          _buildBio(),
          const SizedBox(height: AppDimensions.spacing12),
          _buildFaithInfo(),
          const SizedBox(height: AppDimensions.spacing8),
          _buildInterests(),
        ],
      ),
    );
  }

  Widget _buildNameAndAge() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${widget.profile.firstName}, ${widget.profile.age}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (widget.profile.isOnline)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing8,
              vertical: AppDimensions.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: Text(
              'Online',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationAndDistance() {
    return Row(
      children: [
        const Icon(
          Icons.location_on,
          color: AppColors.white,
          size: 16,
        ),
        const SizedBox(width: AppDimensions.spacing4),
        Text(
          widget.profile.location,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withOpacity(0.9),
              ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Text(
          '• ${widget.profile.distanceText}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildBio() {
    return Text(
      widget.profile.bio,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.white.withOpacity(0.9),
            height: 1.4,
          ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFaithInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.church,
            color: AppColors.white,
            size: 16,
          ),
          const SizedBox(width: AppDimensions.spacing8),
          Flexible(
            child: Text(
              '${widget.profile.denomination} • ${widget.profile.churchAttendance}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterests() {
    final displayInterests = widget.profile.interests.take(3).toList();

    return Wrap(
      spacing: AppDimensions.spacing8,
      runSpacing: AppDimensions.spacing4,
      children: displayInterests.map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing8,
            vertical: AppDimensions.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            interest,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: AppDimensions.paddingM,
      left: AppDimensions.paddingL,
      right: AppDimensions.paddingL,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: AppColors.error,
            onTap: widget.onPass,
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.secondary,
            onTap: widget.onLike,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
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
}
