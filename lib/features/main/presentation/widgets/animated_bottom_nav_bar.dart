import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../pages/main_navigation_screen.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final List<NavigationTab> tabs;
  final int currentIndex;
  final Function(int) onTap;
  final List<Animation<double>> animations;
  final List<int?> badgeCounts;

  const AnimatedBottomNavBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    required this.animations,
    this.badgeCounts = const [null, null, null, null],
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with TickerProviderStateMixin {
  late AnimationController _selectionController;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectionController.reset();
      _selectionController.forward();
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.spacing8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              widget.tabs.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final tab = widget.tabs[index];
    final isSelected = index == widget.currentIndex;

    return AnimatedBuilder(
      animation: widget.animations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animations[index].value.clamp(0.0, 1.0),
          child: Opacity(
            opacity: widget.animations[index].value.clamp(0.0, 1.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing12,
                  vertical: AppDimensions.spacing6,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? tab.gradient : null,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: tab.gradient.colors.first.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedBuilder(
                          animation: _selectionAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: isSelected
                                  ? 1.0 +
                                      (0.2 *
                                          _selectionAnimation.value.clamp(0.0, 1.0))
                                  : 1.0,
                              child: Icon(
                                isSelected ? tab.activeIcon : tab.icon,
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                            );
                          },
                        ),
                        if (widget.badgeCounts[index] != null &&
                            widget.badgeCounts[index]! > 0)
                          Positioned(
                            right: -8,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: AppColors.loveGradient,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                widget.badgeCounts[index]! > 99
                                    ? '99+'
                                    : widget.badgeCounts[index].toString(),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacing2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: isSelected ? 11 : 10,
                          ),
                      child: Text(tab.label),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
