import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class ProfileStatsCard extends StatefulWidget {
  final int likes;
  final int matches;
  final int views;

  const ProfileStatsCard({
    super.key,
    required this.likes,
    required this.matches,
    required this.views,
  });

  @override
  State<ProfileStatsCard> createState() => _ProfileStatsCardState();
}

class _ProfileStatsCardState extends State<ProfileStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late List<Animation<int>> _counterAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _counterAnimations = [
      IntTween(begin: 0, end: widget.likes).animate(CurvedAnimation(
        parent: _counterController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      )),
      IntTween(begin: 0, end: widget.matches).animate(CurvedAnimation(
        parent: _counterController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      )),
      IntTween(begin: 0, end: widget.views).animate(CurvedAnimation(
        parent: _counterController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      )),
    ];
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _counterController.forward();
      }
    });
  }

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingS),
                decoration: BoxDecoration(
                  gradient: AppColors.loveGradient,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.analytics,
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
                      'Profile Stats',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      'Your activity overview',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  animation: _counterAnimations[0],
                  icon: Icons.favorite,
                  label: 'Likes',
                  color: AppColors.secondary,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  animation: _counterAnimations[1],
                  icon: Icons.people,
                  label: 'Matches',
                  color: AppColors.accent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.border.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  animation: _counterAnimations[2],
                  icon: Icons.visibility,
                  label: 'Views',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required Animation<int> animation,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                icon,
                color: color,
                size: AppDimensions.iconS,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              animation.value.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        );
      },
    );
  }
}
