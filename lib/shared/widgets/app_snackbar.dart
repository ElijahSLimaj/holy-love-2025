import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum SnackbarType {
  success,
  error,
  info, // default/info state
}

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getIcon(type),
            color: AppColors.white,
            size: AppDimensions.iconS,
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: _getBackgroundColor(type),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      margin: const EdgeInsets.all(AppDimensions.spacing16),
      elevation: 4,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: AppColors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.info:
        return Icons.info_outline;
    }
  }

  static Color _getBackgroundColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return AppColors.success;
      case SnackbarType.error:
        return AppColors.error;
      case SnackbarType.info:
        return AppColors.primary;
    }
  }
}