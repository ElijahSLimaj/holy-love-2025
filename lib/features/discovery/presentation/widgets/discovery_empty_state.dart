import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../pages/discovery_filters_screen.dart';

/// Beautiful empty state widget for when no profiles are available
class DiscoveryEmptyState extends StatefulWidget {
  final VoidCallback? onRefresh;
  final bool isSwipeMode;

  const DiscoveryEmptyState({
    super.key,
    this.onRefresh,
    this.isSwipeMode = false,
  });

  @override
  State<DiscoveryEmptyState> createState() => _DiscoveryEmptyStateState();
}

class _DiscoveryEmptyStateState extends State<DiscoveryEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildContent(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 200,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.spacing24),
              
              // Beautiful illustration
              _buildIllustration(),
              
              const SizedBox(height: AppDimensions.spacing24),
              
              // Main message
              Text(
                widget.isSwipeMode ? 'No More Profiles' : 'No Profiles Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppDimensions.spacing12),
              
              // Subtitle message
              Text(
                _getSubtitleMessage(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppDimensions.spacing24),
              
              // Action buttons
              _buildActionButtons(context),
              
              const SizedBox(height: AppDimensions.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Adjust size based on screen height
        final screenHeight = MediaQuery.of(context).size.height;
        final size = screenHeight < 600 ? 80.0 : 120.0;
        
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circles for depth (proportional to main size)
              Container(
                width: size * 0.67,
                height: size * 0.67,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: size * 0.42,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              
              // Heart icon in center (proportional to main size)
              Icon(
                widget.isSwipeMode ? Icons.favorite_outline : Icons.search,
                size: size * 0.27,
                color: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getSubtitleMessage() {
    if (widget.isSwipeMode) {
      return "You've seen all available profiles in your area!\nCheck back later for new members, or try adjusting your preferences.";
    } else {
      return "We're still building our community!\nBe one of the first to complete your profile and help others find their perfect match.";
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: AppDimensions.spacing12),
        
        // Secondary action button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToFilters(context),
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Preferences'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.spacing16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          ),
        ),
        
        if (!widget.isSwipeMode) ...[
          const SizedBox(height: AppDimensions.spacing16),
          
          // Additional helpful tips (only show if enough space)
          LayoutBuilder(
            builder: (context, constraints) {
              // Only show tips if we have enough vertical space
              if (MediaQuery.of(context).size.height > 600) {
                return _buildHelpfulTips(context);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHelpfulTips(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                'Tips to find more matches:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing8),
          _buildTip('• Expand your distance range'),
          _buildTip('• Broaden your age preferences'),
          _buildTip('• Complete your profile to attract more matches'),
          _buildTip('• Invite friends to join the community'),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _navigateToFilters(BuildContext context) async {
    HapticFeedback.lightImpact();
    
    // Show filter screen as modal
    await showModalBottomSheet<FilterCriteria>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primary.withOpacity(0.2),
      builder: (context) => const DiscoveryFiltersScreen(),
    );
  }
}
