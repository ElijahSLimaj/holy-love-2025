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
import '../../data/models/notification_item.dart';
import '../../data/repositories/notification_repository.dart';
import '../../../messages/presentation/pages/chat_screen.dart';
import '../../../discovery/presentation/pages/member_profile_screen.dart';

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

  final NotificationRepository _notificationRepository = NotificationRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  String _selectedFilter = 'All';
  bool _isLoading = true;
  StreamSubscription<List<NotificationItem>>? _notificationsSubscription;

  final List<String> _filterOptions = [
    'All',
    'Matches',
    'Messages',
    'Likes',
    'Views'
  ];

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

  Future<void> _loadNotifications() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) {
      setState(() => _isLoading = false);
      return;
    }

    _notificationsSubscription = _notificationRepository
        .streamUserNotifications()
        .listen((notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _applyFilter();
          _isLoading = false;
        });
      }
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
            return notification.type == NotificationType.like;
          case 'Views':
            return notification.type == NotificationType.profileView;
          default:
            return true;
        }
      }).toList();
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
    _notificationsSubscription?.cancel();
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
                  _buildFilterChips(),
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
    final unreadCount = _notifications.where((n) => !n.isRead).length;

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
                      padding: const EdgeInsets.all(AppDimensions.spacing8),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
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
                      Icons.notifications,
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
                          AppStrings.notifications,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        Text(
                          '$unreadCount unread • ${_notifications.length} total',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: Text(
                        'Mark all read',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
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

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacing8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = filter;
                  _applyFilter();
                });
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (_filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              'You\'re all caught up!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          itemCount: _filteredNotifications.length,
          itemBuilder: (context, index) {
            final notification = _filteredNotifications[index];
            final delay = index * 0.05;
            final progress = (_listController.value - delay).clamp(0.0, 1.0);
            final animationValue = Curves.easeOut.transform(progress).clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(30 * (1 - animationValue), 0),
              child: Opacity(
                opacity: animationValue,
                child: _buildNotificationTile(notification),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationTile(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      decoration: BoxDecoration(
        color: notification.isRead ? AppColors.surface : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: notification.isRead
              ? AppColors.border.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.2),
          width: notification.isRead ? 1 : 2,
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
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppDimensions.spacing4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                      ),
                    ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.match:
        icon = Icons.favorite;
        color = AppColors.accent;
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble;
        color = AppColors.primary;
        break;
      case NotificationType.like:
        icon = Icons.thumb_up;
        color = AppColors.primaryLight;
        break;
      case NotificationType.profileView:
        icon = Icons.visibility;
        color = AppColors.success;
        break;
      case NotificationType.system:
        icon = Icons.info;
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Icon(
        icon,
        color: color,
        size: AppDimensions.iconS,
      ),
    );
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
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    HapticFeedback.lightImpact();

    if (!notification.isRead) {
      await _notificationRepository.markAsRead(notification.id);
    }

    if (notification.relatedUserId == null) return;

    try {
      final profile = await _profileRepository.getProfile(notification.relatedUserId!);
      if (profile == null) return;

      final userProfile = UserProfile.fromProfileData(
        profile,
        await _profileRepository.getProfileDetails(notification.relatedUserId!),
      );

      if (!mounted) return;

      if (notification.type == NotificationType.message) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(user: userProfile),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MemberProfileScreen(user: userProfile),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.lightImpact();
    await _notificationRepository.markAllAsRead();
  }
}
