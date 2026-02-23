import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import '../../../discovery/presentation/pages/discovery_screen.dart';
import '../../../matches/presentation/pages/matches_screen.dart';
import '../../../messages/presentation/pages/messages_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../notifications/presentation/pages/notifications_screen.dart';
import '../../../notifications/data/repositories/notification_repository.dart';
import '../../../discovery/presentation/pages/discovery_filters_screen.dart';
import '../../../messages/data/repositories/message_repository.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _navigationController;
  late AnimationController _fadeController;
  late AnimationController _toggleAnimationController;
  late List<Animation<double>> _tabAnimations;
  late Animation<double> _fadeAnimation;
  late Animation<double> _toggleScaleAnimation;

  int _currentIndex = 0;
  int _unreadNotificationCount = 0;
  int _unreadMessagesCount = 0;
  int _unreadMatchesCount = 0;
  StreamSubscription<int>? _notificationSubscription;
  StreamSubscription<int>? _messagesSubscription;
  StreamSubscription<int>? _matchesSubscription;
  final NotificationRepository _notificationRepository = NotificationRepository();
  final MessageRepository _messageRepository = MessageRepository();
  // ViewMode _currentViewMode = ViewMode.list; // Swipe mode disabled - using list view only

  final List<NavigationTab> _tabs = [
    const NavigationTab(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Discovery',
      gradient: AppColors.loveGradient,
    ),
    const NavigationTab(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Matches',
      gradient: LinearGradient(
        colors: [AppColors.accent, AppColors.accentLight],
      ),
    ),
    const NavigationTab(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Messages',
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.primaryLight],
      ),
    ),
    const NavigationTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      gradient: LinearGradient(
        colors: [AppColors.secondary, AppColors.secondaryLight],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();
    _startInitialAnimations();
    _listenToNotifications();
  }

  void _listenToNotifications() {
    _notificationSubscription = _notificationRepository.streamUnreadCount().listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      },
      onError: (error) {
        // Silently fail - keep count at 0
      },
    );

    _messagesSubscription = _messageRepository.streamUnreadCount().listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadMessagesCount = count;
          });
        }
      },
      onError: (error) {
        // Silently fail - keep count at 0
      },
    );

    _matchesSubscription = _notificationRepository.streamUnreadMatchCount().listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadMatchesCount = count;
          });
        }
      },
      onError: (error) {
        // Silently fail - keep count at 0
      },
    );
  }

  void _setupControllers() {
    _pageController = PageController();
    _navigationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _setupAnimations() {
    // Create individual animations for each tab
    _tabAnimations = List.generate(_tabs.length, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _navigationController,
        curve: Interval(
          index * 0.1,
          0.4 + (index * 0.1),
          curve: Curves.easeOutBack,
        ),
      ));
    });

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _toggleScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _toggleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startInitialAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _navigationController.forward();
      _fadeController.forward();
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  // Swipe mode disabled - toggle function commented out
  // void _toggleViewMode() {
  //   if (_currentIndex != 0) return;
  //
  //   HapticFeedback.mediumImpact();
  //   _toggleAnimationController.forward().then((_) {
  //     _toggleAnimationController.reverse();
  //   });
  //
  //   setState(() {
  //     _currentViewMode =
  //         _currentViewMode == ViewMode.list ? ViewMode.swipe : ViewMode.list;
  //   });
  // }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _messagesSubscription?.cancel();
    _matchesSubscription?.cancel();
    _pageController.dispose();
    _navigationController.dispose();
    _fadeController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                    child: _buildPageView(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        tabs: _tabs,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        animations: _tabAnimations,
        badgeCounts: [
          null, // Discovery - no badge
          _unreadMatchesCount > 0 ? _unreadMatchesCount : null, // Matches
          _unreadMessagesCount > 0 ? _unreadMessagesCount : null, // Messages
          null, // Profile - no badge
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingM,
      ),
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
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.loveGradient.createShader(bounds),
            child: Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
            ),
          ),
          const Spacer(),
          _buildViewToggle(),
          const SizedBox(width: AppDimensions.spacing8),
          _buildNotificationAction(),
          const SizedBox(width: AppDimensions.spacing8),
          _buildFilterAction(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return const SizedBox.shrink();
  }

  Widget _buildNotificationAction() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const NotificationsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, -1.0),
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
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacing8),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: AppColors.loveGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  _unreadNotificationCount > 99 ? '99+' : _unreadNotificationCount.toString(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterAction() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();

        // Show filter screen as modal
        final FilterCriteria? result =
            await showModalBottomSheet<FilterCriteria>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: AppColors.primary.withOpacity(0.2),
          builder: (context) => const DiscoveryFiltersScreen(),
        );

        if (result != null) {
          // Handle filter result - in a real app this would update the discovery results
          // For now, just show a snackbar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Filters applied successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing8),
        decoration: BoxDecoration(
          color: AppColors.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: const Icon(
          Icons.tune,
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        const DiscoveryScreen(viewMode: ViewMode.list), // Hardcoded to list view only
        const MatchesScreen(),
        const MessagesScreen(),
        const ProfileScreen(),
      ],
    );
  }
}

class NavigationTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final LinearGradient gradient;

  const NavigationTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.gradient,
  });
}
