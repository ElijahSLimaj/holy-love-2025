import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/custom_button.dart';

class ProfileCompletionCard extends StatefulWidget {
  final int completion;
  final int photoCount;
  final int maxPhotos;
  final VoidCallback onCompleteProfile;

  const ProfileCompletionCard({
    super.key,
    required this.completion,
    required this.photoCount,
    required this.maxPhotos,
    required this.onCompleteProfile,
  });

  @override
  State<ProfileCompletionCard> createState() => _ProfileCompletionCardState();
}

class _ProfileCompletionCardState extends State<ProfileCompletionCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.completion / 100.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _progressController.forward();
        
        if (widget.completion < 100) {
          _pulseController.repeat(reverse: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _progressColor {
    if (widget.completion >= 90) return AppColors.success;
    if (widget.completion >= 70) return AppColors.accent;
    if (widget.completion >= 50) return AppColors.secondary;
    return AppColors.primary;
  }

  String get _completionMessage {
    if (widget.completion >= 95) return 'Your profile looks amazing! 🌟';
    if (widget.completion >= 80) return 'Almost there! Just a few more details';
    if (widget.completion >= 60) return 'Good progress! Keep going';
    return 'Let\'s complete your profile';
  }

  List<String> get _missingItems {
    List<String> missing = [];
    
    if (widget.photoCount < widget.maxPhotos) {
      missing.add('Add ${widget.maxPhotos - widget.photoCount} more photos');
    }
    
    if (widget.completion < 100) {
      if (widget.completion < 80) missing.add('Complete your bio');
      if (widget.completion < 90) missing.add('Add your interests');
      if (widget.completion < 95) missing.add('Share your favorite verse');
    }
    
    return missing;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.completion < 100 ? _pulseAnimation : 
          const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
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
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: _progressColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: _progressColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: AppDimensions.spacing20),
                _buildProgressSection(),
                const SizedBox(height: AppDimensions.spacing20),
                if (_missingItems.isNotEmpty) ...[
                  _buildMissingItems(),
                  const SizedBox(height: AppDimensions.spacing20),
                ],
                if (widget.completion < 100) _buildActionButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_progressColor, _progressColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            boxShadow: [
              BoxShadow(
                color: _progressColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.completion >= 95 ? Icons.check_circle : Icons.account_circle,
            color: AppColors.white,
            size: AppDimensions.iconS,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Completion',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _completionMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.completion}% Complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _progressColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: _progressColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                '${widget.photoCount}/${widget.maxPhotos} photos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _progressColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMissingItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'To complete your profile:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        ..._missingItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacing4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: _progressColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Expanded(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: AppStrings.completeProfile,
        onPressed: () {
          HapticFeedback.lightImpact();
          widget.onCompleteProfile();
        },
        variant: ButtonVariant.outline,
        size: ButtonSize.medium,
        customColor: _progressColor,
      ),
    );
  }
} 