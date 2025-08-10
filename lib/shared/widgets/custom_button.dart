import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'gradient_button_wrapper.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  text,
  gradient,
  socialGradientBorder,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? icon;
  final Color? customColor;
  final double? customWidth;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.customColor,
    this.customWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: isFullWidth ? double.infinity : customWidth,
      height: _getButtonHeight(),
      child: _buildButton(theme),
    );
  }

  Widget _buildButton(ThemeData theme) {
    switch (variant) {
      case ButtonVariant.primary:
        return _buildPrimaryButton(theme);
      case ButtonVariant.secondary:
        return _buildSecondaryButton(theme);
      case ButtonVariant.outline:
        return _buildOutlineButton(theme);
      case ButtonVariant.text:
        return _buildTextButton(theme);
      case ButtonVariant.gradient:
        return _buildGradientButton(theme);
      case ButtonVariant.socialGradientBorder:
        return _buildSocialGradientBorderButton(theme);
    }
  }

  Widget _buildPrimaryButton(ThemeData theme) {
    // Use gradient for primary buttons unless a custom color is specified
    if (customColor == null) {
      return _buildGradientButton(theme);
    }

    // Fallback to solid color when custom color is provided
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: customColor,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildSecondaryButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: customColor ?? AppColors.lightGray,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildOutlineButton(ThemeData theme) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: customColor ?? AppColors.primary,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        side: BorderSide(
          color: customColor ?? AppColors.primary,
          width: 1.5,
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildTextButton(ThemeData theme) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: customColor ?? AppColors.primary,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: _getButtonPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        textStyle: _getTextStyle(),
      ),
      child: _buildButtonContent(),
    );
  }

  Widget _buildGradientButton(ThemeData theme) {
    return GradientButtonWrapper(
      onPressed: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      padding: _getButtonPadding(),
      child: Align(
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: _getTextStyle().copyWith(
            color: AppColors.textOnPrimary,
          ),
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildSocialGradientBorderButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.loveGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.5), // Border width
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM - 1.5),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: _getButtonPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM - 1.5),
            ),
            textStyle: _getTextStyle(),
          ),
          child: _buildButtonContent(),
        ),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: const CircularProgressIndicator(
          color: AppColors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppDimensions.spacing8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return AppDimensions.buttonHeightS;
      case ButtonSize.medium:
        return AppDimensions.buttonHeightM;
      case ButtonSize.large:
        return AppDimensions.buttonHeightL;
    }
  }

  EdgeInsets _getButtonPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingXS,
        );
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingL,
          vertical: AppDimensions.paddingS,
        );
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppDimensions.buttonPaddingHorizontal,
          vertical: AppDimensions.buttonPaddingVertical,
        );
    }
  }

  TextStyle _getTextStyle() {
    final baseFontSize = size == ButtonSize.small ? 14.0 : 16.0;

    return TextStyle(
      fontSize: baseFontSize,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );
  }

  double _getLoadingSize() {
    switch (size) {
      case ButtonSize.small:
        return 16.0;
      case ButtonSize.medium:
        return 20.0;
      case ButtonSize.large:
        return 24.0;
    }
  }
}

// Convenience constructors for common button types
extension CustomButtonExtensions on CustomButton {
  static CustomButton primary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = true,
    Widget? icon,
    double? customWidth,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      customWidth: customWidth,
    );
  }

  static CustomButton secondary({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = true,
    Widget? icon,
    double? customWidth,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      customWidth: customWidth,
    );
  }

  static CustomButton outline({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = true,
    Widget? icon,
    double? customWidth,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.outline,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      customWidth: customWidth,
    );
  }

  static CustomButton gradient({
    Key? key,
    required String text,
    required VoidCallback? onPressed,
    ButtonSize size = ButtonSize.medium,
    bool isLoading = false,
    bool isFullWidth = true,
    Widget? icon,
    double? customWidth,
  }) {
    return CustomButton(
      key: key,
      text: text,
      onPressed: onPressed,
      variant: ButtonVariant.gradient,
      size: size,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
      icon: icon,
      customWidth: customWidth,
    );
  }
}
