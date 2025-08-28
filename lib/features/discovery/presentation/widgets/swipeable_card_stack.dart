import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/models/user_profile.dart';
import 'profile_card.dart';

class SwipeableCardStack extends StatefulWidget {
  final List<UserProfile> profiles;
  final Function(UserProfile profile) onLike;
  final Function(UserProfile profile) onPass;
  final Function(UserProfile profile) onCardTap;
  final VoidCallback? onStackEmpty;

  const SwipeableCardStack({
    super.key,
    required this.profiles,
    required this.onLike,
    required this.onPass,
    required this.onCardTap,
    this.onStackEmpty,
  });

  @override
  State<SwipeableCardStack> createState() => SwipeableCardStackState();
}

class SwipeableCardStackState extends State<SwipeableCardStack>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _scaleController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  int _currentIndex = 0;
  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  // Constants for swipe behavior
  static const double _swipeThreshold = 100.0;
  static const double _rotationFactor = 0.1;
  static const int _visibleCards = 3;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  bool get _hasMoreCards => _currentIndex < widget.profiles.length;

  UserProfile? get _currentProfile =>
      _hasMoreCards ? widget.profiles[_currentIndex] : null;

  @override
  Widget build(BuildContext context) {
    if (!_hasMoreCards) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 600,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards
          for (int i = _visibleCards - 1; i >= 0; i--)
            if (_currentIndex + i < widget.profiles.length)
              _buildCard(
                widget.profiles[_currentIndex + i],
                i,
              ),
        ],
      ),
    );
  }

  Widget _buildCard(UserProfile profile, int stackIndex) {
    final isTopCard = stackIndex == 0;
    final scale = isTopCard ? 1.0 : (1.0 - (stackIndex * 0.05));
    final yOffset = stackIndex * 8.0;

    Widget card = ProfileCard(
      profile: profile,
      showActions: false,
      onTap: () => widget.onCardTap(profile),
    );

    if (isTopCard) {
      // Add swipe animations to top card
      card = AnimatedBuilder(
        animation: Listenable.merge([
          _swipeController,
          _scaleController,
        ]),
        builder: (context, child) {
          final swipeOffset =
              _isDragging ? _dragPosition : _swipeAnimation.value;

          final rotation = _isDragging
              ? _dragPosition.dx * _rotationFactor / 1000
              : _rotationAnimation.value;

          final cardScale = _isDragging ? _scaleAnimation.value : 1.0;

          return Transform.translate(
            offset: Offset(swipeOffset.dx, swipeOffset.dy + yOffset),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: cardScale,
                child: child,
              ),
            ),
          );
        },
        child: card,
      );

      // Add gesture detection to top card
      card = GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    } else {
      // Static positioning for background cards - no complex animations
      card = Transform.translate(
        offset: Offset(0, yOffset),
        child: Transform.scale(
          scale: scale,
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 600,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              decoration: const BoxDecoration(
                gradient: AppColors.loveGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline,
                size: 64,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              'No More Profiles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            Text(
              'Check back later for new matches!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Reset any ongoing animations first
    _swipeController.stop();
    _swipeController.reset();
    _scaleController.stop();

    _dragStart = details.localPosition;
    _isDragging = true;
    _dragPosition = Offset.zero; // Reset drag position

    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragPosition = details.localPosition - _dragStart;
    });

    // Provide haptic feedback at swipe threshold
    if (_dragPosition.dx.abs() > _swipeThreshold &&
        _dragPosition.dx.abs() < _swipeThreshold + 10) {
      HapticFeedback.selectionClick();
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;
    _scaleController.reverse();

    final velocity = details.velocity.pixelsPerSecond;
    final isSwipeLeft =
        _dragPosition.dx < -_swipeThreshold || velocity.dx < -1000;
    final isSwipeRight =
        _dragPosition.dx > _swipeThreshold || velocity.dx > 1000;

    if (isSwipeLeft) {
      _animateSwipe(SwipeDirection.left);
    } else if (isSwipeRight) {
      _animateSwipe(SwipeDirection.right);
    } else {
      _animateReturn();
    }
  }

  void _animateSwipe(SwipeDirection direction) {
    final screenWidth = MediaQuery.of(context).size.width;
    final endX = direction == SwipeDirection.left ? -screenWidth : screenWidth;
    final endY =
        _dragPosition.dy + (direction == SwipeDirection.left ? 100 : -100);

    _swipeAnimation = Tween<Offset>(
      begin: _dragPosition,
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragPosition.dx * _rotationFactor / 1000,
      end: direction == SwipeDirection.left ? -0.5 : 0.5,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutCubic,
    ));

    _swipeController.forward().then((_) {
      _onSwipeComplete(direction);
    });

    // Haptic feedback for successful swipe
    HapticFeedback.mediumImpact();
  }

  void _animateReturn() {
    _swipeAnimation = Tween<Offset>(
      begin: _dragPosition,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: _dragPosition.dx * _rotationFactor / 1000,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOutBack,
    ));

    _swipeController.forward().then((_) {
      _swipeController.reset();
      _scaleController.reverse(); // Reset scale animation
      setState(() {
        _dragPosition = Offset.zero;
        _isDragging = false; // Ensure dragging state is reset
      });
    });
  }

  void _onSwipeComplete(SwipeDirection direction) {
    if (_currentProfile == null) return;

    if (direction == SwipeDirection.left) {
      widget.onPass(_currentProfile!);
    } else {
      widget.onLike(_currentProfile!);
    }

    setState(() {
      _currentIndex++;
      _dragPosition = Offset.zero;
      _isDragging = false; // Ensure dragging state is reset
    });

    // Reset all animation states after updating the index
    _swipeController.reset();
    _scaleController.reset();

    if (!_hasMoreCards) {
      widget.onStackEmpty?.call();
    }
  }

  // Public methods for programmatic swiping
  void swipeLeft() {
    if (!_hasMoreCards || _isDragging) return;

    // Reset any ongoing animations
    _swipeController.stop();
    _swipeController.reset();
    _scaleController.stop();
    _scaleController.reset();

    setState(() {
      _dragPosition = Offset.zero;
      _isDragging = false;
    });

    _animateSwipe(SwipeDirection.left);
  }

  void swipeRight() {
    if (!_hasMoreCards || _isDragging) return;

    // Reset any ongoing animations
    _swipeController.stop();
    _swipeController.reset();
    _scaleController.stop();
    _scaleController.reset();

    setState(() {
      _dragPosition = Offset.zero;
      _isDragging = false;
    });

    _animateSwipe(SwipeDirection.right);
  }
}

enum SwipeDirection { left, right }
