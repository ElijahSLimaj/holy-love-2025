import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/services/subscription_service.dart';
import '../../data/services/purchase_service.dart';

enum PaywallTrigger {
  profileViews,
  likes,
  passes,
  messaging,
  readReceipts,
  whoViewedMe,
}

class PaywallScreen extends StatefulWidget {
  final PaywallTrigger trigger;

  const PaywallScreen({
    super.key,
    required this.trigger,
  });

  static void show(BuildContext context, PaywallTrigger trigger) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.primary.withOpacity(0.2),
      builder: (context) => PaywallScreen(trigger: trigger),
    );
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedPlanIndex = 2; // Default to annual (best value)
  bool _isLoading = false;
  bool _isPurchasing = false;
  String? _userId;

  final SubscriptionService _subscriptionService = SubscriptionService();

  // Product IDs mapped to plan indices
  static const List<String> _productIds = [
    ProductIds.monthly,
    ProductIds.quarterly,
    ProductIds.annual,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.authenticated) {
      _userId = authState.user.id;
      await _subscriptionService.initializePurchases(_userId!);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing || _userId == null) return;

    setState(() => _isPurchasing = true);
    HapticFeedback.mediumImpact();

    try {
      final productId = _productIds[_selectedPlanIndex];
      final result = await _subscriptionService.purchaseService.purchase(productId);

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Welcome to Holy Love Pro!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Purchase failed. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final result = await _subscriptionService.purchaseService.restorePurchases();

      if (!mounted) return;

      if (result.success) {
        // Check if we're now premium
        final isPremium = await _subscriptionService.purchaseService.checkSubscriptionStatus();
        if (isPremium) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Subscription restored successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No previous purchases found.'),
              backgroundColor: AppColors.textSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Could not restore purchases.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _triggerTitle {
    switch (widget.trigger) {
      case PaywallTrigger.profileViews:
        return "You've used all 5 profile views today";
      case PaywallTrigger.likes:
        return "You've used all 5 likes today";
      case PaywallTrigger.passes:
        return "You've used all 5 passes today";
      case PaywallTrigger.messaging:
        return 'Upgrade to message anyone directly';
      case PaywallTrigger.readReceipts:
        return 'See when your messages are read';
      case PaywallTrigger.whoViewedMe:
        return "See who's been viewing your profile";
    }
  }

  IconData get _triggerIcon {
    switch (widget.trigger) {
      case PaywallTrigger.profileViews:
        return Icons.visibility;
      case PaywallTrigger.likes:
        return Icons.favorite;
      case PaywallTrigger.passes:
        return Icons.close;
      case PaywallTrigger.messaging:
        return Icons.chat_bubble;
      case PaywallTrigger.readReceipts:
        return Icons.done_all;
      case PaywallTrigger.whoViewedMe:
        return Icons.remove_red_eye;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusXL),
                topRight: Radius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  _buildHandle(),
                  _buildHeader(),
                  const SizedBox(height: AppDimensions.spacing24),
                  _buildBenefitsList(),
                  const SizedBox(height: AppDimensions.spacing32),
                  _buildPricingPlans(),
                  const SizedBox(height: AppDimensions.spacing24),
                  _buildPurchaseButton(),
                  const SizedBox(height: AppDimensions.spacing16),
                  _buildRestoreButton(),
                  const SizedBox(height: AppDimensions.spacing32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacing12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _triggerIcon,
              color: AppColors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.loveGradient.createShader(bounds),
            child: Text(
              'Holy Love Pro',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            _triggerTitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      _BenefitItem(
        icon: Icons.visibility,
        title: 'Unlimited Profile Views',
        subtitle: 'Browse as many profiles as you want',
      ),
      _BenefitItem(
        icon: Icons.favorite,
        title: 'Unlimited Likes & Passes',
        subtitle: 'No daily limits on interactions',
      ),
      _BenefitItem(
        icon: Icons.chat_bubble,
        title: 'Message Anyone Directly',
        subtitle: 'Start conversations without matching first',
      ),
      _BenefitItem(
        icon: Icons.done_all,
        title: 'Read Receipts',
        subtitle: 'Know when your messages are read',
      ),
      _BenefitItem(
        icon: Icons.remove_red_eye,
        title: 'See Who Viewed You',
        subtitle: 'Find out who checked your profile',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Column(
        children: benefits.map((benefit) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    gradient: AppColors.loveGradient.scale(0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    benefit.icon,
                    color: AppColors.primary,
                    size: AppDimensions.iconS,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit.title,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                      ),
                      Text(
                        benefit.subtitle,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: AppDimensions.iconS,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingPlans() {
    final plans = [
      _PricingPlan(
        title: 'Monthly',
        price: '\$19.99',
        period: '/month',
        savings: null,
      ),
      _PricingPlan(
        title: '3 Months',
        price: '\$13.99',
        period: '/month',
        savings: 'Save 30%',
      ),
      _PricingPlan(
        title: 'Annual',
        price: '\$8.99',
        period: '/month',
        savings: 'Save 55%',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Row(
        children: plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          final isSelected = _selectedPlanIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedPlanIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                  right: index < plans.length - 1 ? AppDimensions.spacing8 : 0,
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.loveGradient : null,
                  color: isSelected ? null : AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusL),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppColors.border,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    if (plan.savings != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingXS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.white.withOpacity(0.3)
                              : AppColors.accent.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusS),
                        ),
                        child: Text(
                          plan.savings!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing4),
                    ] else
                      const SizedBox(height: 22),
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      plan.price,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      plan.period,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isPurchasing ? null : _handlePurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.paddingL,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            elevation: 4,
          ),
          child: _isPurchasing
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleRestore,
      child: _isLoading
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
              ),
            )
          : Text(
              'Restore Purchases',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                  ),
            ),
    );
  }
}

class _BenefitItem {
  final IconData icon;
  final String title;
  final String subtitle;

  _BenefitItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _PricingPlan {
  final String title;
  final String price;
  final String period;
  final String? savings;

  _PricingPlan({
    required this.title,
    required this.price,
    required this.period,
    this.savings,
  });
}
