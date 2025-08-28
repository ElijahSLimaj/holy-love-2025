import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../pages/matches_screen.dart';

class ConversationTile extends StatefulWidget {
  final ConversationData conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: AppColors.surface,
      end: AppColors.lightGray.withOpacity(0.5),
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.conversation.unreadCount > 0;

    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin:
                const EdgeInsets.symmetric(vertical: AppDimensions.spacing4),
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              border: Border.all(
                color: hasUnread
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.border.withOpacity(0.1),
                width: hasUnread ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                onTapDown: (_) => _pressController.forward(),
                onTapUp: (_) => _pressController.reverse(),
                onTapCancel: () => _pressController.reverse(),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: AppDimensions.spacing16),
                      Expanded(
                        child: _buildMessageContent(),
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      _buildTrailingInfo(),
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

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: AppDimensions.avatarL,
          height: AppDimensions.avatarL,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.conversation.user.isOnline
                  ? AppColors.success
                  : AppColors.border,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: AppColors.textSecondary,
            size: AppDimensions.iconL,
          ),
        ),
        // Online status indicator
        if (widget.conversation.user.isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
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
    );
  }

  Widget _buildMessageContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.conversation.user.fullName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.conversation.user.isOnline)
              Container(
                margin: const EdgeInsets.only(left: AppDimensions.spacing8),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  'Online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          widget.conversation.lastMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: widget.conversation.unreadCount > 0
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: widget.conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildTrailingInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatTimestamp(widget.conversation.timestamp),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.conversation.unreadCount > 0
                    ? AppColors.primary
                    : AppColors.textTertiary,
                fontWeight: widget.conversation.unreadCount > 0
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        if (widget.conversation.unreadCount > 0)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.conversation.unreadCount > 9
                    ? '9+'
                    : widget.conversation.unreadCount.toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
              ),
            ),
          )
        else
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
