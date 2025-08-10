import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback? onStartTyping;
  final VoidCallback? onStopTyping;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onStartTyping,
    this.onStopTyping,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _sendButtonController;
  late AnimationController _attachmentController;
  late Animation<double> _sendButtonScaleAnimation;
  late Animation<double> _sendButtonRotationAnimation;
  late Animation<double> _attachmentFadeAnimation;

  bool _hasText = false;
  bool _showAttachments = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTextListener();
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _attachmentController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeOutBack,
    ));

    _sendButtonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));

    _attachmentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _attachmentController,
      curve: Curves.easeOut,
    ));
  }

  void _setupTextListener() {
    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });

        if (hasText) {
          _sendButtonController.forward();
          widget.onStartTyping?.call();
        } else {
          _sendButtonController.reverse();
          widget.onStopTyping?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showAttachments) _buildAttachmentOptions(),
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildAttachmentButton(),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(child: _buildTextInput()),
              const SizedBox(width: AppDimensions.spacing12),
              _buildSendButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _showAttachments = !_showAttachments;
        });

        if (_showAttachments) {
          _attachmentController.forward();
        } else {
          _attachmentController.reverse();
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          _showAttachments ? Icons.close : Icons.add,
          color: AppColors.textSecondary,
          size: AppDimensions.iconM,
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 44,
        maxHeight: 120,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: _focusNode.hasFocus
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.border.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
        decoration: InputDecoration(
          hintText: AppStrings.typeMessage,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textTertiary,
              ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
        ),
        onSubmitted: (_) => _handleSend(),
      ),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendButtonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonScaleAnimation.value,
          child: Transform.rotate(
            angle: _sendButtonRotationAnimation.value * 3.14159 * 2,
            child: GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: _hasText ? AppColors.loveGradient : null,
                  color: _hasText ? null : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _hasText ? AppColors.white : AppColors.textTertiary,
                  size: AppDimensions.iconM,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOptions() {
    return AnimatedBuilder(
      animation: _attachmentFadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _attachmentFadeAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_camera,
                  label: 'Camera',
                  color: AppColors.primary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Open camera
                    _showComingSoon('Camera feature');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppColors.secondary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Open gallery
                    _showComingSoon('Gallery feature');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.favorite,
                  label: 'Prayer',
                  color: AppColors.accent,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Share prayer request
                    _showComingSoon('Prayer request sharing');
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.menu_book,
                  label: 'Verse',
                  color: AppColors.success,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: Share Bible verse
                    _showComingSoon('Bible verse sharing');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconM,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
}
