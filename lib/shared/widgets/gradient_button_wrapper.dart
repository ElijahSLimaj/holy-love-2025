import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A reusable wrapper that adds gradient background to any button widget
/// Follows SOLID principles by being a single-responsibility decorator
class GradientButtonWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final List<BoxShadow>? boxShadow;

  const GradientButtonWrapper({
    super.key,
    required this.child,
    required this.onPressed,
    this.borderRadius,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppDimensions.radiusM);

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.loveGradient,
        borderRadius: effectiveBorderRadius,
        boxShadow: boxShadow ?? AppColors.buttonShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: effectiveBorderRadius,
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppDimensions.buttonPaddingHorizontal,
                  vertical: AppDimensions.buttonPaddingVertical,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Extension to easily wrap any widget with gradient background
extension GradientWrapper on Widget {
  Widget withGradientBackground({
    required VoidCallback? onPressed,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    List<BoxShadow>? boxShadow,
  }) {
    return GradientButtonWrapper(
      onPressed: onPressed,
      borderRadius: borderRadius,
      padding: padding,
      boxShadow: boxShadow,
      child: this,
    );
  }
}
