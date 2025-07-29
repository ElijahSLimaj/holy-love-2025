import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../pages/chat_screen.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool showAvatar;
  final UserProfile user;

  const MessageBubble({
    super.key,
    required this.message,
    required this.showAvatar,
    required this.user,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _slideAnimation = Tween<Offset>(
      begin: widget.message.isFromCurrentUser 
          ? const Offset(0.3, 0)
          : const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  void _startAnimation() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
              child: Row(
                mainAxisAlignment: widget.message.isFromCurrentUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!widget.message.isFromCurrentUser) ...[
                    _buildAvatar(),
                    const SizedBox(width: AppDimensions.spacing8),
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: widget.message.isFromCurrentUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        _buildMessageBubble(),
                        const SizedBox(height: AppDimensions.spacing4),
                        _buildMessageInfo(),
                      ],
                    ),
                  ),
                  if (widget.message.isFromCurrentUser) ...[
                    const SizedBox(width: AppDimensions.spacing8),
                    _buildMessageStatus(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar() {
    return Opacity(
      opacity: widget.showAvatar ? 1.0 : 0.0,
      child: Container(
        width: AppDimensions.avatarS,
        height: AppDimensions.avatarS,
        decoration: const BoxDecoration(
          color: AppColors.lightGray,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: AppColors.textSecondary,
          size: AppDimensions.iconS,
        ),
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
      decoration: BoxDecoration(
        gradient: widget.message.isFromCurrentUser
            ? AppColors.loveGradient
            : null,
        color: widget.message.isFromCurrentUser
            ? null
            : AppColors.lightGray,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppDimensions.radiusL),
          topRight: const Radius.circular(AppDimensions.radiusL),
          bottomLeft: Radius.circular(
            widget.message.isFromCurrentUser 
                ? AppDimensions.radiusL 
                : AppDimensions.radiusS,
          ),
          bottomRight: Radius.circular(
            widget.message.isFromCurrentUser 
                ? AppDimensions.radiusS 
                : AppDimensions.radiusL,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.message.isFromCurrentUser
                ? AppColors.primary.withOpacity(0.2)
                : AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: widget.message.isFromCurrentUser
              ? AppColors.white
              : AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.message.isFromCurrentUser ? 0 : AppDimensions.spacing8,
        right: widget.message.isFromCurrentUser ? AppDimensions.spacing8 : 0,
      ),
      child: Text(
        _formatTime(widget.message.timestamp),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textTertiary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!widget.message.isFromCurrentUser) return const SizedBox.shrink();

    Widget statusIcon;
    Color statusColor;

    switch (widget.message.status) {
      case MessageStatus.sending:
        statusIcon = const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColors.textTertiary,
          ),
        );
        statusColor = AppColors.textTertiary;
        break;
      case MessageStatus.delivered:
        statusIcon = const Icon(
          Icons.check,
          size: 14,
        );
        statusColor = AppColors.textTertiary;
        break;
      case MessageStatus.read:
        statusIcon = const Icon(
          Icons.done_all,
          size: 14,
        );
        statusColor = AppColors.primary;
        break;
      case MessageStatus.failed:
        statusIcon = const Icon(
          Icons.error_outline,
          size: 14,
        );
        statusColor = AppColors.error;
        break;
    }

    return Container(
      width: 20,
      height: 20,
      child: IconTheme(
        data: IconThemeData(color: statusColor),
        child: statusIcon,
      ),
    );
  }
} 