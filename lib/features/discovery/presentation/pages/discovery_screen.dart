import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/mock_users.dart';
import '../../data/models/user_profile.dart';
import '../widgets/swipeable_card_stack.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  List<UserProfile> _profiles = [];
  bool _isLoading = true;
  
  // Key to access the swipeable card stack
  final GlobalKey<SwipeableCardStackState> _cardStackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProfiles();
    _startAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardController = AnimationController(
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _cardController.forward();
      }
    }
  }

  void _loadProfiles() async {
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _profiles = MockUsers.getDiscoveryProfiles();
        _isLoading = false;
      });
    }
  }

  void _onLike(UserProfile profile) {
    print('Liked: ${profile.firstName}');
    // TODO: Handle like action
  }

  void _onPass(UserProfile profile) {
    print('Passed: ${profile.firstName}');
    // TODO: Handle pass action
  }

  void _onCardTap(UserProfile profile) {
    print('Tapped: ${profile.firstName}');
    // TODO: Navigate to profile details
  }

  void _onStackEmpty() {
    print('No more profiles');
    // TODO: Load more profiles or show empty state
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: _buildContent(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacing20),
          _buildWelcomeSection(),
          const SizedBox(height: AppDimensions.spacing32),
          Expanded(
            child: SwipeableCardStack(
              key: _cardStackKey,
              profiles: _profiles,
              onLike: _onLike,
              onPass: _onPass,
              onCardTap: _onCardTap,
              onStackEmpty: _onStackEmpty,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.loveGradient.createShader(bounds),
          child: Text(
            'Discover Your Match',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Text(
          'Find meaningful connections with fellow Christians',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          Text(
            'Finding Your Matches...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'We\'re preparing amazing profiles just for you!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.close,
          color: AppColors.error,
          onTap: () {
            _cardStackKey.currentState?.swipeLeft();
          },
        ),
        _buildActionButton(
          icon: Icons.tune,
          color: AppColors.accent,
          onTap: () {
            // TODO: Open filters/preferences
          },
        ),
        _buildActionButton(
          icon: Icons.favorite,
          color: AppColors.secondary,
          onTap: () {
            _cardStackKey.currentState?.swipeRight();
          },
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final size = isLarge ? 64.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppColors.white,
          size: iconSize,
        ),
      ),
    );
  }
} 