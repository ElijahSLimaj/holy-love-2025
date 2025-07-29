import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../discovery/data/models/user_profile.dart';
import '../../../discovery/data/mock_users.dart';
import '../../../messages/presentation/pages/chat_screen.dart';
import '../../../discovery/presentation/pages/member_profile_screen.dart';

enum NotificationType {
  match,
  message,
  like,
  view,
  prayerRequest,
  verseShare,
  churchEvent,
  premium
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final UserProfile? user;
  final String? imageUrl;
  final VoidCallback? onTap;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.user,
    this.imageUrl,
    this.onTap,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _headerController;
  late AnimationController _listController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;

  final List<String> _filterOptions = ['All', 'Matches', 'Messages', 'Likes', 'Faith'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadNotifications();
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

  void _loadNotifications() {
    final profiles = MockUsers.sampleProfiles;
    
    _notifications = [
      NotificationItem(
        id: '1',
        type: NotificationType.match,
        title: 'New Match! 💕',
        message: 'You and ${profiles[0].firstName} liked each other! Start a conversation now.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        user: profiles[0],
        onTap: () => _navigateToProfile(profiles[0]),
      ),
      NotificationItem(
        id: '2',
        type: NotificationType.message,
        title: 'New Message from ${profiles[1].firstName}',
        message: 'Hey! I love your testimony about serving in children\'s ministry 🙏',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        user: profiles[1],
        onTap: () => _navigateToChat(profiles[1]),
      ),
      NotificationItem(
        id: '3',
        type: NotificationType.like,
        title: '${profiles[2].firstName} liked you!',
        message: 'Someone special is interested in getting to know you better.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        user: profiles[2],
        onTap: () => _navigateToProfile(profiles[2]),
      ),
      NotificationItem(
        id: '4',
        type: NotificationType.verseShare,
        title: 'Daily Verse Shared',
        message: '${profiles[3].firstName} shared their favorite verse: "For I know the plans I have for you..."',
        timestamp: DateTime.now().subtract(const Duration(hours: 6)),
        user: profiles[3],
        onTap: () => _navigateToChat(profiles[3]),
      ),
      NotificationItem(
        id: '5',
        type: NotificationType.view,
        title: 'Profile Views',
        message: '5 people viewed your profile today! Keep your profile updated.',
        timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      NotificationItem(
        id: '6',
        type: NotificationType.prayerRequest,
        title: 'Prayer Request Response',
        message: '${profiles[4].firstName} responded to your prayer request with encouragement.',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
        user: profiles[4],
        onTap: () => _navigateToChat(profiles[4]),
      ),
      NotificationItem(
        id: '7',
        type: NotificationType.churchEvent,
        title: 'Local Church Event',
        message: 'New Christian singles event near you this Saturday - "Faith & Fellowship"',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      NotificationItem(
        id: '8',
        type: NotificationType.like,
        title: '${profiles[5].firstName} liked your photo',
        message: 'Your mission trip photo caught someone\'s attention!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        user: profiles[5],
        onTap: () => _navigateToProfile(profiles[5]),
      ),
      NotificationItem(
        id: '9',
        type: NotificationType.premium,
        title: 'Premium Feature Available',
        message: 'See who liked you first! Upgrade to Premium for enhanced matching.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
      NotificationItem(
        id: '10',
        type: NotificationType.match,
        title: 'Another Match! ✨',
        message: 'You and ${profiles[6].firstName} are both looking for meaningful connections.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        user: profiles[6],
        onTap: () => _navigateToProfile(profiles[6]),
      ),
    ];

    _applyFilter();
    
    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilter() {
    if (_selectedFilter == 'All') {
      _filteredNotifications = _notifications;
    } else {
      _filteredNotifications = _notifications.where((notification) {
        switch (_selectedFilter) {
          case 'Matches':
            return notification.type == NotificationType.match;
          case 'Messages':
            return notification.type == NotificationType.message;
          case 'Likes':
            return notification.type == NotificationType.like || 
                   notification.type == NotificationType.view;
          case 'Faith':
            return notification.type == NotificationType.prayerRequest ||
                   notification.type == NotificationType.verseShare ||
                   notification.type == NotificationType.churchEvent;
          default:
            return true;
        }
      }).toList();
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
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
            return Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildFilterTabs(),
                  Expanded(
                    child: _buildNotificationsList(),
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
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.primary,
                        size: AppDimensions.iconM,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.notifications,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${_notifications.where((n) => !n.isRead).length} unread • ${_filteredNotifications.length} total',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _markAllAsRead();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        gradient: AppColors.loveGradient,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                      child: const Icon(
                        Icons.done_all,
                        color: AppColors.white,
                        size: AppDimensions.iconM,
                      ),
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

  Widget _buildFilterTabs() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            height: 50,
            margin: const EdgeInsets.only(top: AppDimensions.spacing8, bottom: AppDimensions.spacing8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedFilter = filter;
                      _applyFilter();
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: AppDimensions.spacing12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingM,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.loveGradient : null,
                      color: isSelected ? null : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.transparent 
                            : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: isSelected ? AppColors.cardShadow : null,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList() {
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Opacity(
          opacity: _listController.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _listController.value)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              itemCount: _filteredNotifications.length,
              itemBuilder: (context, index) {
                final notification = _filteredNotifications[index];
                
                return AnimatedBuilder(
                  animation: _listController,
                  builder: (context, child) {
                    final delay = index * 0.1;
                    final progress = (_listController.value - delay).clamp(0.0, 1.0);
                    final animationValue = Curves.easeOut.transform(progress).clamp(0.0, 1.0);
                    
                    return Transform.translate(
                      offset: Offset(30 * (1 - animationValue), 0),
                      child: Opacity(
                        opacity: animationValue,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
                          child: _buildNotificationTile(notification),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        notification.onTap?.call();
        _markAsRead(notification);
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: notification.isRead 
              ? AppColors.cardBackground 
              : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: notification.isRead 
                ? AppColors.border 
                : AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: notification.isRead ? null : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon/avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _getNotificationGradient(notification.type),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: AppColors.white,
                size: AppDimensions.iconM,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            
            // Notification content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacing4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // User avatar if available
            if (notification.user != null)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: AppDimensions.spacing8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM - 2),
                  child: Image.network(
                    notification.user!.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.cardBackground,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingXL),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient.scale(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          Text(
            'No ${_selectedFilter == 'All' ? '' : _selectedFilter.toLowerCase()} notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            'When something happens, you\'ll see it here!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return Icons.favorite;
      case NotificationType.message:
        return Icons.chat_bubble;
      case NotificationType.like:
        return Icons.thumb_up;
      case NotificationType.view:
        return Icons.visibility;
      case NotificationType.prayerRequest:
        return Icons.pan_tool;
      case NotificationType.verseShare:
        return Icons.auto_stories;
      case NotificationType.churchEvent:
        return Icons.church;
      case NotificationType.premium:
        return Icons.star;
    }
  }

  LinearGradient _getNotificationGradient(NotificationType type) {
    switch (type) {
      case NotificationType.match:
        return AppColors.loveGradient;
      case NotificationType.message:
        return const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
        );
      case NotificationType.like:
        return const LinearGradient(
          colors: [AppColors.success, Color(0xFF4CAF50)],
        );
      case NotificationType.view:
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        );
      case NotificationType.prayerRequest:
        return const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
        );
      case NotificationType.verseShare:
        return const LinearGradient(
          colors: [Color(0xFF3F51B5), Color(0xFF7986CB)],
        );
      case NotificationType.churchEvent:
        return const LinearGradient(
          colors: [Color(0xFF795548), Color(0xFFA1887F)],
        );
      case NotificationType.premium:
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _markAsRead(NotificationItem notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index >= 0) {
        _notifications[index] = NotificationItem(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          isRead: true,
          user: notification.user,
          imageUrl: notification.imageUrl,
          onTap: notification.onTap,
        );
        _applyFilter();
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((notification) {
        return NotificationItem(
          id: notification.id,
          type: notification.type,
          title: notification.title,
          message: notification.message,
          timestamp: notification.timestamp,
          isRead: true,
          user: notification.user,
          imageUrl: notification.imageUrl,
          onTap: notification.onTap,
        );
      }).toList();
      _applyFilter();
    });
  }

  void _navigateToProfile(UserProfile user) {
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

  void _navigateToChat(UserProfile user) {
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
} 