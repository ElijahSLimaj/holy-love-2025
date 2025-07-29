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
  ViewMode _currentViewMode = ViewMode.list;
  
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

  void _toggleViewMode() {
    if (_currentIndex != 0) return; // Only works on discovery screen
    
    HapticFeedback.mediumImpact();
    _toggleAnimationController.forward().then((_) {
      _toggleAnimationController.reverse();
    });
    
    setState(() {
      _currentViewMode = _currentViewMode == ViewMode.list 
          ? ViewMode.swipe 
          : ViewMode.list;
    });
  }

  @override
  void dispose() {
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
            shaderCallback: (bounds) => AppColors.loveGradient.createShader(bounds),
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
          _buildHeaderAction(
            icon: Icons.tune,
            onTap: () {
              HapticFeedback.lightImpact();
              // TODO: Show filters/settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    // Only show on discovery screen
    if (_currentIndex != 0) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _toggleAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _toggleScaleAnimation.value,
          child: GestureDetector(
            onTap: _toggleViewMode,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.spacing8),
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                _currentViewMode == ViewMode.list 
                    ? Icons.view_carousel_outlined
                    : Icons.view_list_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationAction() {
    // Mock unread count - in a real app this would come from a state management solution
    const int unreadCount = 3;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const NotificationsScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
          if (unreadCount > 0)
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
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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

  Widget _buildHeaderAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacing8),
        decoration: BoxDecoration(
          color: AppColors.lightGray.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        ),
        child: Icon(
          icon,
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
        DiscoveryScreen(viewMode: _currentViewMode),
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