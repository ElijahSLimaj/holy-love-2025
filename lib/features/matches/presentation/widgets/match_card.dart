import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../discovery/data/models/user_profile.dart';

class MatchCard extends StatefulWidget {
  final UserProfile user;
  final VoidCallback onTap;
  final VoidCallback onMessageTap;

  const MatchCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onMessageTap,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value
              .clamp(0.1, 2.0), // Prevent invalid scale values
          child: Container(
            margin: const EdgeInsets.only(
                bottom: AppDimensions.spacing16), // Added bottom margin
            child: SizedBox(
              width: 120, // Reduced from 140
              height: 200, // Reduced from 250
              child: Material(
                elevation: _elevationAnimation.value
                    .clamp(0.0, 24.0), // Clamp elevation
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.white,
                        AppColors.offWhite,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.border.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildContent(),
                      _buildMatchBadge(),
                      // Properly contained InkWell
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusL),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onTap();
                            },
                            onTapDown: (_) => _hoverController.forward(),
                            onTapUp: (_) => _hoverController.reverse(),
                            onTapCancel: () => _hoverController.reverse(),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusL),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Profile photo section
        Expanded(
          flex: 2, // Reduced to give MORE space to info
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Stack(
              children: [
                // Photo placeholder with gradient
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.lightGray,
                        AppColors.lightGray.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppDimensions.radiusL),
                      topRight: Radius.circular(AppDimensions.radiusL),
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Online status indicator
                if (widget.user.isOnline)
                  Positioned(
                    top: AppDimensions.spacing8,
                    right: AppDimensions.spacing8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Info section - Use Expanded to fit available space
        Expanded(
          flex: 3, // MUCH more space for text content
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
                AppDimensions.paddingS), // Reduced padding for smaller card
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.user.firstName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14, // Reduced from 15
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4), // Added explicit spacing
                Flexible(
                  child: Text(
                    '${widget.user.age}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 12, // Reduced from 13
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 6), // Added explicit spacing
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, // Reduced padding for smaller card
                    vertical: 3, // Reduced padding for smaller card
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    widget.user.denomination.length > 10
                        ? '${widget.user.denomination.substring(0, 10)}...'
                        : widget.user.denomination,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 9, // Reduced from 10
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchBadge() {
    return Positioned(
      top: AppDimensions.spacing8,
      left: AppDimensions.spacing8,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8, // Reduced padding
          vertical: 4, // Reduced padding
        ),
        decoration: BoxDecoration(
          gradient: AppColors.loveGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite,
              color: AppColors.white,
              size: 10, // Reduced size
            ),
            const SizedBox(width: 4), // Reduced spacing
            Text(
              'Match',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 9, // Reduced font size
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
