import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../profile/data/repositories/stats_repository.dart';

/// Product IDs - must match App Store Connect / Google Play Console
class ProductIds {
  static const String monthly = 'holy_love_pro_monthly';
  static const String quarterly = 'holy_love_pro_quarterly';
  static const String annual = 'holy_love_pro_annual';

  static const Set<String> all = {monthly, quarterly, annual};
}

/// Purchase result from attempting a purchase
class PurchaseResult {
  final bool success;
  final String? error;
  final String? productId;

  const PurchaseResult({
    required this.success,
    this.error,
    this.productId,
  });
}

/// Abstract interface for purchase service (allows dev/prod swap)
abstract class PurchaseServiceBase {
  Future<void> initialize(String userId);
  Future<List<ProductDetails>> getProducts();
  Future<PurchaseResult> purchase(String productId);
  Future<PurchaseResult> restorePurchases();
  Future<bool> checkSubscriptionStatus();
  void dispose();
  Stream<bool> get premiumStatusStream;
}

/// Production purchase service using in_app_purchase
class PurchaseService implements PurchaseServiceBase {
  final InAppPurchase _iap = InAppPurchase.instance;
  final StatsRepository _statsRepository = StatsRepository();

  String? _userId;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  final _premiumStatusController = StreamController<bool>.broadcast();

  // Firebase Functions URL for receipt validation
  // TODO: Update this when deploying to production
  static const String _validateReceiptUrl =
      'https://us-central1-holy-love-2025-07-11.cloudfunctions.net/validateReceipt';

  @override
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  @override
  Future<void> initialize(String userId) async {
    _userId = userId;

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('PurchaseService: Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('PurchaseService: Purchase stream error: $error');
      },
    );

    // Load products
    await _loadProducts();

    // Check current status
    await checkSubscriptionStatus();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(ProductIds.all);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('PurchaseService: Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('PurchaseService: Loaded ${_products.length} products');
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('PurchaseService: Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Validate receipt server-side
          final valid = await _validateReceipt(purchase);
          if (valid) {
            await _updatePremiumStatus(true);
          }

          // Complete the purchase
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          debugPrint('PurchaseService: Purchase error: ${purchase.error?.message}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('PurchaseService: Purchase canceled');
          break;
      }
    }
  }

  Future<bool> _validateReceipt(PurchaseDetails purchase) async {
    if (_userId == null) return false;

    try {
      final receiptData = Platform.isIOS
          ? purchase.verificationData.localVerificationData
          : purchase.verificationData.serverVerificationData;

      final response = await http.post(
        Uri.parse(_validateReceiptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'receipt': receiptData,
          'productId': purchase.productID,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] == true;
      }

      debugPrint('PurchaseService: Receipt validation failed: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('PurchaseService: Receipt validation error: $e');
      return false;
    }
  }

  Future<void> _updatePremiumStatus(bool isPremium) async {
    if (_userId == null) return;

    await _statsRepository.updatePremiumStatus(_userId!, isPremium);
    _premiumStatusController.add(isPremium);
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }
    return _products;
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found: $productId'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);

      if (!success) {
        return const PurchaseResult(
          success: false,
          error: 'Purchase could not be initiated',
        );
      }

      // The actual result will come through the purchase stream
      return PurchaseResult(success: true, productId: productId);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      return const PurchaseResult(success: true);
    } catch (e) {
      return PurchaseResult(success: false, error: e.toString());
    }
  }

  @override
  Future<bool> checkSubscriptionStatus() async {
    if (_userId == null) return false;

    final stats = await _statsRepository.getUserStats(_userId!);
    final isPremium = stats?.isPremium ?? false;
    _premiumStatusController.add(isPremium);
    return isPremium;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _premiumStatusController.close();
  }
}

/// Dev/mock purchase service for testing without real store
class DevPurchaseService implements PurchaseServiceBase {
  final StatsRepository _statsRepository = StatsRepository();
  String? _userId;
  final _premiumStatusController = StreamController<bool>.broadcast();

  // Simulated products
  final List<MockProductDetails> _mockProducts = [
    MockProductDetails(
      id: ProductIds.monthly,
      title: 'Holy Love Pro Monthly',
      description: 'Unlimited access for 1 month',
      price: '\$19.99',
      rawPrice: 19.99,
    ),
    MockProductDetails(
      id: ProductIds.quarterly,
      title: 'Holy Love Pro 3 Months',
      description: 'Unlimited access for 3 months - Save 30%',
      price: '\$41.97',
      rawPrice: 41.97,
    ),
    MockProductDetails(
      id: ProductIds.annual,
      title: 'Holy Love Pro Annual',
      description: 'Unlimited access for 1 year - Save 55%',
      price: '\$107.88',
      rawPrice: 107.88,
    ),
  ];

  @override
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;

  @override
  Future<void> initialize(String userId) async {
    _userId = userId;
    debugPrint('DevPurchaseService: Initialized for user $userId');
    await checkSubscriptionStatus();
  }

  @override
  Future<List<ProductDetails>> getProducts() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockProducts;
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    debugPrint('DevPurchaseService: Mock purchase of $productId');

    // Simulate purchase flow
    await Future.delayed(const Duration(milliseconds: 500));

    // Always succeed in dev mode
    await _updatePremiumStatus(true);

    return PurchaseResult(success: true, productId: productId);
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    debugPrint('DevPurchaseService: Mock restore purchases');
    await Future.delayed(const Duration(milliseconds: 300));

    // Check if user was previously premium
    final stats = await _statsRepository.getUserStats(_userId!);
    if (stats?.isPremium ?? false) {
      _premiumStatusController.add(true);
      return const PurchaseResult(success: true);
    }

    return const PurchaseResult(
      success: false,
      error: 'No previous purchases found',
    );
  }

  @override
  Future<bool> checkSubscriptionStatus() async {
    if (_userId == null) return false;

    final stats = await _statsRepository.getUserStats(_userId!);
    final isPremium = stats?.isPremium ?? false;
    _premiumStatusController.add(isPremium);
    return isPremium;
  }

  Future<void> _updatePremiumStatus(bool isPremium) async {
    if (_userId == null) return;

    await _statsRepository.updatePremiumStatus(_userId!, isPremium);
    _premiumStatusController.add(isPremium);
  }

  /// Dev-only: Toggle premium status for testing
  Future<void> togglePremium() async {
    if (_userId == null) return;

    final stats = await _statsRepository.getUserStats(_userId!);
    final currentlyPremium = stats?.isPremium ?? false;
    await _updatePremiumStatus(!currentlyPremium);
    debugPrint('DevPurchaseService: Toggled premium to ${!currentlyPremium}');
  }

  /// Dev-only: Set premium status directly
  Future<void> setPremium(bool isPremium) async {
    await _updatePremiumStatus(isPremium);
    debugPrint('DevPurchaseService: Set premium to $isPremium');
  }

  @override
  void dispose() {
    _premiumStatusController.close();
  }
}

/// Mock ProductDetails for dev mode
class MockProductDetails implements ProductDetails {
  @override
  final String id;

  @override
  final String title;

  @override
  final String description;

  @override
  final String price;

  @override
  final double rawPrice;

  @override
  final String currencyCode = 'USD';

  @override
  final String currencySymbol = '\$';

  MockProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
  });
}

/// Factory to get the appropriate purchase service based on environment
class PurchaseServiceFactory {
  static bool _useDevService = kDebugMode;

  /// Override to force dev mode even in release
  static void setDevMode(bool devMode) {
    _useDevService = devMode;
  }

  /// Get the appropriate service instance
  static PurchaseServiceBase create() {
    if (_useDevService) {
      debugPrint('PurchaseServiceFactory: Using DevPurchaseService');
      return DevPurchaseService();
    }
    debugPrint('PurchaseServiceFactory: Using PurchaseService');
    return PurchaseService();
  }
}
