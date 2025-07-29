import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../discovery/data/mock_users.dart';
import '../../../matches/presentation/widgets/conversation_tile.dart';
import '../../../matches/presentation/pages/matches_screen.dart'; // For ConversationData
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

  // Mock data for conversations
  List<ConversationData> _conversations = [];
  bool _isLoading = true;

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

  void _loadConversations() {
    // Load the same conversations as in matches screen plus additional ones
    final allProfiles = MockUsers.sampleProfiles;
    
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
      ConversationData(
        user: allProfiles[5],
        lastMessage: 'Hope you\'re having a blessed week! Looking forward to hearing from you 😊',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        unreadCount: 0,
      ),
      ConversationData(
        user: allProfiles[6],
        lastMessage: 'Thank you for sharing that verse with me. It really spoke to my heart 💖',
        timestamp: DateTime.now().subtract(const Duration(days: 4)),
        unreadCount: 3,
      ),
      ConversationData(
        user: allProfiles[7],
        lastMessage: 'I love how passionate you are about your faith! Would love to learn more about your church',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        unreadCount: 0,
      ),
    ];

    setState(() {
      _isLoading = false;
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
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_conversations.where((c) => c.unreadCount > 0).length} unread • ${_conversations.length} total conversations',
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
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: _listController.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _listController.value)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
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
                  Icon(
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
          final conversation = entry.value;
          
          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              // Safe animation calculation for conversations
              final delay = index * 0.1;
              final progress = (_listController.value - delay).clamp(0.0, 1.0);
              final animationValue = Curves.easeOut.transform(progress).clamp(0.0, 1.0);
              
              return Transform.translate(
                offset: Offset(30 * (1 - animationValue), 0),
                child: Opacity(
                  opacity: animationValue,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
                    child: ConversationTile(
                      key: ValueKey('messages_conversation_${conversation.user.id}'),
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