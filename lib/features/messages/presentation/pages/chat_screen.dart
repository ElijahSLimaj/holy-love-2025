import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/presence_service.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/conversation_data.dart';
import '../../data/repositories/message_repository.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../profile/data/repositories/stats_repository.dart';
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
  final MessageRepository _messageRepository = MessageRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  final StatsRepository _statsRepository = StatsRepository();
  final PresenceService _presenceService = PresenceService();

  List<ChatMessage> _messages = [];
  ConversationData? _conversation;
  String? _conversationId;
  String? _currentUserId;
  bool _isTyping = false;
  bool _isOnline = false;
  Timer? _typingTimer;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<ConversationData?>? _conversationSubscription;
  StreamSubscription<PresenceStatus>? _presenceSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeChat();
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

  Future<void> _initializeChat() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) return;

    _currentUserId = authState.user.id;
    if (_currentUserId == null) return;

    _conversationId = _messageRepository.generateConversationId(
      _currentUserId!,
      widget.user.id,
    );

    final conversation = await _messageRepository.getConversation(_conversationId!);
    if (conversation == null) {
      await _messageRepository.createConversation(otherUserId: widget.user.id);
    }

    _conversationSubscription = _messageRepository
        .streamConversation(_conversationId!)
        .listen((conversation) {
      if (mounted && conversation != null) {
        setState(() {
          _conversation = conversation;
          _isTyping = conversation.isTyping(widget.user.id);
        });
      }
    });

    _messagesSubscription = _messageRepository
        .streamMessages(_conversationId!)
        .listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages.reversed.toList();
        });

        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });

        _messageRepository.markMessagesAsRead(conversationId: _conversationId!);
      }
    });

    _presenceSubscription = _presenceService
        .streamUserStatus(widget.user.id)
        .listen((status) {
      if (mounted) {
        setState(() {
          _isOnline = status == PresenceStatus.online;
        });
      }
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _slideController.forward();
      _fadeController.forward();

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
    _messagesSubscription?.cancel();
    _conversationSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingTimer?.cancel();
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
                child: widget.user.photoUrls.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          widget.user.photoUrls.first,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
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
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              'Start your conversation',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final previousMessage = index > 0 ? _messages[index - 1] : null;
        final showAvatar = previousMessage == null ||
            (previousMessage.senderId != message.senderId);

        return MessageBubble(
          message: message,
          showAvatar: showAvatar,
          user: widget.user,
          isFromCurrentUser: message.senderId == _currentUserId,
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
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              shape: BoxShape.circle,
              image: widget.user.photoUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.user.photoUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.user.photoUrls.isEmpty
                ? const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconS,
                  )
                : null,
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
            _messageRepository.setTypingStatus(
              conversationId: _conversationId!,
              isTyping: true,
            );

            _typingTimer?.cancel();
            _typingTimer = Timer(const Duration(seconds: 3), () {
              _messageRepository.setTypingStatus(
                conversationId: _conversationId!,
                isTyping: false,
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty || _conversationId == null || _currentUserId == null) {
      return;
    }

    HapticFeedback.lightImpact();

    try {
      await _messageRepository.sendMessage(
        conversationId: _conversationId!,
        receiverId: widget.user.id,
        text: text.trim(),
      );

      await _statsRepository.incrementMessagesSent(_currentUserId!);
      await _statsRepository.incrementMessagesReceived(widget.user.id);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
