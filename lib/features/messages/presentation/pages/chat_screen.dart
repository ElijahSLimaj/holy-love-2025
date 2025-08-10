import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile user;

  const ChatScreen({
    super.key,
    required this.user,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMockMessages();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _loadMockMessages() {
    _messages.addAll([
      ChatMessage(
        id: '1',
        text:
            'Hey! Thanks for the match! I love your testimony about serving in children\'s ministry 🙏',
        isFromCurrentUser: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '2',
        text:
            'Thank you so much! That means a lot to me. I saw that you\'re into rock climbing - that looks so fun!',
        isFromCurrentUser: true,
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '3',
        text:
            'It really is! There\'s something so peaceful about being up there, just you and God\'s creation. Have you ever tried it?',
        isFromCurrentUser: false,
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '4',
        text:
            'Not yet, but I\'ve always wanted to! Maybe you could show me some beginner-friendly spots? 😊',
        isFromCurrentUser: true,
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '5',
        text:
            'I\'d love to! There\'s this great indoor climbing gym that\'s perfect for beginners. Plus they have a really welcoming community there.',
        isFromCurrentUser: false,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MessageStatus.read,
      ),
      ChatMessage(
        id: '6',
        text: 'That sounds perfect! When would be a good time for you?',
        isFromCurrentUser: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        status: MessageStatus.delivered,
      ),
    ]);
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _slideController.forward();
      _fadeController.forward();

      // Scroll to bottom after animations
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMessagesList(),
              ),
            ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildChatInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                width: AppDimensions.avatarM,
                height: AppDimensions.avatarM,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isOnline ? AppColors.success : AppColors.border,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textSecondary,
                  size: AppDimensions.iconM,
                ),
              ),
              if (_isOnline)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
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
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  _isOnline ? AppStrings.online : widget.user.onlineStatusText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isOnline
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // TODO: Start voice call
          },
          icon: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingXS),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.call,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            // TODO: Start video call
          },
          icon: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingXS),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.videocam,
              color: AppColors.textSecondary,
              size: AppDimensions.iconS,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final previousMessage = index > 0 ? _messages[index - 1] : null;
        final showAvatar = previousMessage == null ||
            previousMessage.isFromCurrentUser != message.isFromCurrentUser;

        return MessageBubble(
          message: message,
          showAvatar: showAvatar,
          user: widget.user,
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: AppDimensions.spacing12),
          const TypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: ChatInput(
          onSendMessage: _handleSendMessage,
          onStartTyping: () {
            setState(() => _isTyping = true);
            // Simulate typing stopping after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _isTyping = false);
              }
            });
          },
        ),
      ),
    );
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isFromCurrentUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.add(newMessage);
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] =
                newMessage.copyWith(status: MessageStatus.delivered);
          }
        });
      }
    });

    // Simulate message read
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(status: MessageStatus.read);
          }
        });
      }
    });
  }
}

// Data classes for chat functionality
class ChatMessage {
  final String id;
  final String text;
  final bool isFromCurrentUser;
  final DateTime timestamp;
  final MessageStatus status;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isFromCurrentUser,
    required this.timestamp,
    required this.status,
    this.imageUrl,
  });

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isFromCurrentUser,
    DateTime? timestamp,
    MessageStatus? status,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isFromCurrentUser: isFromCurrentUser ?? this.isFromCurrentUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

enum MessageStatus {
  sending,
  delivered,
  read,
  failed,
}
