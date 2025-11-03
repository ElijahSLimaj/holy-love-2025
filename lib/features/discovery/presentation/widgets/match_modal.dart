import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/models/user_profile.dart';

class MatchModal extends StatefulWidget {
  final UserProfile matchedUser;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  const MatchModal({
    super.key,
    required this.matchedUser,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  @override
  State<MatchModal> createState() => _MatchModalState();
}

class _MatchModalState extends State<MatchModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _heartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleController.forward();
    _heartController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.paddingXL),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
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
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingXL),
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _heartAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_heartAnimation.value * 0.2),
                              child: Container(
                                padding: const EdgeInsets.all(AppDimensions.paddingL),
                                decoration: BoxDecoration(
                                  gradient: AppColors.loveGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: AppColors.white,
                                  size: 48,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacing24),
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.loveGradient
                              .createShader(bounds),
                          child: Text(
                            'It\'s a Match!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        Text(
                          'You and ${widget.matchedUser.firstName} liked each other',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.spacing32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: ClipOval(
                                child: widget.matchedUser.photoUrls.isNotEmpty
                                    ? Image.network(
                                        widget.matchedUser.photoUrls.first,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: AppColors.lightGray,
                                        child: const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          widget.matchedUser.fullName,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                        ),
                        if (widget.matchedUser.denomination != null)
                          Text(
                            widget.matchedUser.denomination!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppDimensions.radiusXL),
                        bottomRight: Radius.circular(AppDimensions.radiusXL),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onSendMessage();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDimensions.paddingL,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusL),
                              ),
                            ),
                            child: const Text(
                              'Send Message',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing12),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            widget.onKeepSwiping();
                          },
                          child: const Text(
                            'Keep Swiping',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
