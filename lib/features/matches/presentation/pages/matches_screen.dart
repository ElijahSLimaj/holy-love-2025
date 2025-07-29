import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../discovery/data/mock_users.dart';
import '../widgets/match_card.dart';
import '../widgets/conversation_tile.dart';
import '../../../messages/presentation/pages/chat_screen.dart';

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

  // Mock data - in real app this would come from BLoC/repository
  List<UserProfile> _newMatches = [];
  List<ConversationData> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadMockData();
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

  void _loadMockData() {
    // Load some mock matches and conversations
    final allProfiles = MockUsers.sampleProfiles;
    _newMatches = allProfiles.take(4).toList();
    
    _conversations = [
      ConversationData(
        user: allProfiles[0],
        lastMessage: 'Hey! Thanks for the match! I love your testimony about serving in children\'s ministry 🙏',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        unreadCount: 2,
      ),
      ConversationData(
        user: allProfiles[1],
        lastMessage: 'That\'s so cool that you\'re into rock climbing too! Have you tried the routes at...',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
      ),
      ConversationData(
        user: allProfiles[2],
        lastMessage: 'I saw your photos from the mission trip - that must have been amazing! 💕',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        unreadCount: 1,
      ),
      ConversationData(
        user: allProfiles[3],
        lastMessage: 'Would love to hear more about your worship ministry! Maybe we could grab coffee?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 0,
      ),
      ConversationData(
        user: allProfiles[4],
        lastMessage: 'Your favorite verse is so beautiful! It\'s been encouraging me this week ✨',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
      ),
    ];

    setState(() {
      _isLoading = false;
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 150)); // Slightly longer delay
    if (mounted) {
      _fadeController.forward();
      _headerController.forward();
      
      await Future.delayed(const Duration(milliseconds: 400)); // Longer delay
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
                gradient: LinearGradient(
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_newMatches.length} new matches • ${_conversations.length} conversations',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spacing24),
          _buildNewMatchesSection(),
          const SizedBox(height: AppDimensions.spacing32),
          _buildConversationsSection(),
          const SizedBox(height: AppDimensions.spacing24),
        ],
      ),
    );
  }

  Widget _buildNewMatchesSection() {
    if (_newMatches.isEmpty) return const SizedBox.shrink();

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
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spacing8),
                      Text(
                        AppStrings.newMatches,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing16),
                SizedBox(
                  height: 200, // Updated to match smaller card height
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newMatches.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          // Safe animation calculation with proper clamping
                          final delay = index * 0.15;
                          final progress = (_listController.value - delay).clamp(0.0, 1.0);
                          
                          // Use easeOut instead of easeOutBack to avoid overshoot
                          final animationValue = Curves.easeOut.transform(progress).clamp(0.0, 1.0);
                          final scaleValue = (0.7 + (0.3 * animationValue)).clamp(0.0, 1.0);
                          
                          return Transform.scale(
                            scale: scaleValue,
                            child: Opacity(
                              opacity: animationValue,
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: index == _newMatches.length - 1 ? 0 : AppDimensions.spacing16,
                                ),
                                child: MatchCard(
                                  key: ValueKey('match_${_newMatches[index].id}'),
                                  user: _newMatches[index],
                                  onTap: () => _handleMatchTap(_newMatches[index]),
                                  onMessageTap: () => _handleMessageTap(_newMatches[index]),
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
                        // TODO: Navigate to all conversations
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
                  final conversation = entry.value;
                  
                  return AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                      // Safe animation calculation for conversations
                      final delay = 0.3 + (index * 0.1);
                      final progress = (_listController.value - delay).clamp(0.0, 1.0);
                      final animationValue = Curves.easeOut.transform(progress).clamp(0.0, 1.0);
                      
                      return Transform.translate(
                        offset: Offset(30 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                            child: ConversationTile(
                              key: ValueKey('conversation_${conversation.user.id}'),
                              conversation: conversation,
                              onTap: () => _handleConversationTap(conversation),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMatchTap(UserProfile user) {
    HapticFeedback.lightImpact();
    // TODO: Navigate to detailed match view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${user.firstName}\'s profile'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
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

  void _handleConversationTap(ConversationData conversation) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ChatScreen(user: conversation.user),
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

// Data class for conversation information
class ConversationData {
  final UserProfile user;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  ConversationData({
    required this.user,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });
} 