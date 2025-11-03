import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/models/conversation_data.dart';
import '../../data/repositories/message_repository.dart';
import '../../../matches/presentation/widgets/conversation_tile.dart';
import '../../../matches/presentation/pages/matches_screen.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  final MessageRepository _messageRepository = MessageRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  List<ConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  StreamSubscription<List<ConversationData>>? _conversationsSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadConversations();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _listController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));
  }

  Future<void> _loadConversations() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) {
      setState(() => _isLoading = false);
      return;
    }

    _currentUserId = authState.user.id;
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    _conversationsSubscription = _messageRepository
        .streamUserConversations()
        .listen((conversations) async {
      final conversationItems = <ConversationItem>[];

      for (var conversation in conversations) {
        final otherUserId = conversation.getOtherParticipantId(_currentUserId!);
        final profile = await _profileRepository.getProfile(otherUserId);

        if (profile != null) {
          final userProfile = UserProfile.fromProfileData(
            profile,
            await _profileRepository.getProfileDetails(otherUserId),
          );

          conversationItems.add(ConversationItem(
            conversation: conversation,
            user: userProfile,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _conversations = conversationItems;
          _isLoading = false;
        });
      }
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) {
      _fadeController.forward();
      _headerController.forward();

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _listController.forward();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerController.dispose();
    _listController.dispose();
    _conversationsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            final opacityValue = _fadeAnimation.value.clamp(0.0, 1.0);
            return Opacity(
              opacity: opacityValue,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _conversations.where((c) =>
        c.conversation.getUnreadCount(_currentUserId ?? '') > 0).length;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: SlideTransition(
            position: _headerSlideAnimation,
            child: Container(
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: AppColors.textOnPrimary,
                      size: AppDimensions.iconM,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.messages,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          '$unreadCount unread • ${_conversations.length} total conversations',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: _listController.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _listController.value)),
            child: _conversations.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppDimensions.spacing24),
                        _buildActiveConversations(),
                        const SizedBox(height: AppDimensions.spacing24),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
            'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Start matching with people to begin conversations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveConversations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient.scale(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.forum,
                    color: AppColors.primary,
                    size: AppDimensions.iconS,
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  Text(
                    'Active Conversations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing16),
        ..._conversations.asMap().entries.map((entry) {
          final index = entry.key;
          final conversationItem = entry.value;

          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              final delay = index * 0.1;
              final progress = (_listController.value - delay).clamp(0.0, 1.0);
              final animationValue =
                  Curves.easeOut.transform(progress).clamp(0.0, 1.0);

              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue,
                  child: Container(
                    margin:
                        const EdgeInsets.only(bottom: AppDimensions.spacing8),
                    child: ConversationTile(
                      key: ValueKey(
                          'messages_conversation_${conversationItem.user.id}'),
                      conversation: conversationItem.toDisplayData(_currentUserId ?? ''),
                      onTap: () => _handleConversationTap(conversationItem),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  void _handleConversationTap(ConversationItem conversationItem) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(user: conversationItem.user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

class ConversationItem {
  final ConversationData conversation;
  final UserProfile user;

  ConversationItem({
    required this.conversation,
    required this.user,
  });

  DisplayConversationData toDisplayData(String currentUserId) {
    return DisplayConversationData(
      user: user,
      lastMessage: conversation.lastMessage ?? '',
      timestamp: conversation.lastMessageAt ?? conversation.createdAt,
      unreadCount: conversation.getUnreadCount(currentUserId),
    );
  }
}
