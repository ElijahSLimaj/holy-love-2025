import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../discovery/data/services/interaction_service.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../messages/data/repositories/message_repository.dart';
import '../../../messages/data/models/conversation_data.dart';
import '../widgets/match_card.dart';
import '../widgets/conversation_tile.dart';
import '../../../messages/presentation/pages/chat_screen.dart';
import '../../../discovery/presentation/pages/member_profile_screen.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  final InteractionService _interactionService = InteractionService();
  final ProfileRepository _profileRepository = ProfileRepository();
  final MessageRepository _messageRepository = MessageRepository();

  List<UserProfile> _newMatches = [];
  List<ConversationItem> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
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
      duration: const Duration(milliseconds: 1200),
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

  Future<void> _loadData() async {
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

    try {
      final matchedUserIds = await _interactionService.getUserMatches(_currentUserId!);
      final matchProfiles = <UserProfile>[];

      for (var userId in matchedUserIds.take(10)) {
        final profile = await _profileRepository.getProfile(userId);
        if (profile != null) {
          final userProfile = UserProfile.fromProfileData(
            profile,
            await _profileRepository.getProfileDetails(userId),
          );
          matchProfiles.add(userProfile);
        }
      }

      final recentConversations = await _messageRepository.getRecentConversations(limit: 5);
      final conversationItems = <ConversationItem>[];

      for (var conversation in recentConversations) {
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
          _newMatches = matchProfiles;
          _conversations = conversationItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading matches: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(
                      Icons.people,
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
                          AppStrings.matches,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          '${_newMatches.length} matches • ${_conversations.length} conversations',
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
    if (_newMatches.isEmpty && _conversations.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing24),
          if (_newMatches.isNotEmpty) ...[
            _buildNewMatchesSection(),
            const SizedBox(height: AppDimensions.spacing32),
          ],
          if (_conversations.isNotEmpty) ...[
            _buildConversationsSection(),
            const SizedBox(height: AppDimensions.spacing24),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          Text(
            'No matches yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'Start swiping to find your matches',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textTertiary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNewMatchesSection() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: _listController.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _listController.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      Text(
                        AppStrings.newMatches,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newMatches.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          final delay = index * 0.15;
                          final progress =
                              (_listController.value - delay).clamp(0.0, 1.0);

                          final animationValue = Curves.easeOut
                              .transform(progress)
                              .clamp(0.0, 1.0);
                          final scaleValue =
                              (0.7 + (0.3 * animationValue)).clamp(0.0, 1.0);

                          return Transform.scale(
                            scale: scaleValue,
                            child: Opacity(
                              opacity: animationValue,
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: index == _newMatches.length - 1
                                      ? 0
                                      : AppDimensions.spacing16,
                                ),
                                child: MatchCard(
                                  key: ValueKey(
                                      'match_${_newMatches[index].id}'),
                                  user: _newMatches[index],
                                  onTap: () =>
                                      _handleMatchTap(_newMatches[index]),
                                  onMessageTap: () =>
                                      _handleMessageTap(_newMatches[index]),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsSection() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: _listController.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - _listController.value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      AppStrings.conversations,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Text(
                        'See All',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
                      final delay = 0.3 + (index * 0.1);
                      final progress =
                          (_listController.value - delay).clamp(0.0, 1.0);
                      final animationValue =
                          Curves.easeOut.transform(progress).clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(30 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: AppDimensions.spacing8),
                            child: ConversationTile(
                              key: ValueKey(
                                  'conversation_${conversationItem.user.id}'),
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
            ),
          ),
        );
      },
    );
  }

  void _handleMatchTap(UserProfile user) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            MemberProfileScreen(user: user),
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

  void _handleMessageTap(UserProfile user) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(user: user),
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

class DisplayConversationData {
  final UserProfile user;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  DisplayConversationData({
    required this.user,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });
}
