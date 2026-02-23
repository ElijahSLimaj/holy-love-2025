import 'dart:async';
import '../repositories/daily_usage_repository.dart';
import '../models/daily_usage.dart';
import '../../../profile/data/repositories/stats_repository.dart';
import '../../../discovery/data/services/interaction_service.dart';
import 'purchase_service.dart';

class SubscriptionService {
  final StatsRepository _statsRepository;
  final DailyUsageRepository _dailyUsageRepository;
  final InteractionService _interactionService;
  late final PurchaseServiceBase _purchaseService;

  // Cache premium status to avoid repeated Firestore reads
  bool? _cachedIsPremium;
  String? _cachedUserId;
  StreamSubscription<bool>? _premiumSubscription;

  SubscriptionService({
    StatsRepository? statsRepository,
    DailyUsageRepository? dailyUsageRepository,
    InteractionService? interactionService,
    PurchaseServiceBase? purchaseService,
  })  : _statsRepository = statsRepository ?? StatsRepository(),
        _dailyUsageRepository = dailyUsageRepository ?? DailyUsageRepository(),
        _interactionService = interactionService ?? InteractionService() {
    _purchaseService = purchaseService ?? PurchaseServiceFactory.create();
  }

  /// Initialize the purchase service for a user
  Future<void> initializePurchases(String userId) async {
    await _purchaseService.initialize(userId);
    _cachedUserId = userId;

    // Listen for premium status changes from purchase updates
    _premiumSubscription?.cancel();
    _premiumSubscription = _purchaseService.premiumStatusStream.listen((isPremium) {
      _cachedIsPremium = isPremium;
    });
  }

  /// Get the purchase service for direct purchase operations
  PurchaseServiceBase get purchaseService => _purchaseService;

  Future<bool> isPremium(String userId) async {
    if (_cachedUserId == userId && _cachedIsPremium != null) {
      return _cachedIsPremium!;
    }
    final stats = await _statsRepository.getUserStats(userId);
    _cachedIsPremium = stats?.isPremium ?? false;
    _cachedUserId = userId;
    return _cachedIsPremium!;
  }

  Future<bool> canViewProfile(String userId) async {
    if (await isPremium(userId)) return true;
    final usage = await _dailyUsageRepository.getTodaysUsage(userId);
    return usage.canViewProfile;
  }

  Future<bool> canLike(String userId) async {
    if (await isPremium(userId)) return true;
    final usage = await _dailyUsageRepository.getTodaysUsage(userId);
    return usage.canLike;
  }

  Future<bool> canPass(String userId) async {
    if (await isPremium(userId)) return true;
    final usage = await _dailyUsageRepository.getTodaysUsage(userId);
    return usage.canPass;
  }

  Future<bool> canMessage(String userId, String targetUserId) async {
    if (await isPremium(userId)) return true;
    // Free users can only message matches
    final matches = await _interactionService.getUserMatches(userId);
    return matches.contains(targetUserId);
  }

  Future<void> recordProfileView(String userId) async {
    if (await isPremium(userId)) return;
    await _dailyUsageRepository.incrementProfileViews(userId);
  }

  Future<void> recordLike(String userId) async {
    if (await isPremium(userId)) return;
    await _dailyUsageRepository.incrementLikes(userId);
  }

  Future<void> recordPass(String userId) async {
    if (await isPremium(userId)) return;
    await _dailyUsageRepository.incrementPasses(userId);
  }

  Future<DailyUsage> getDailyUsage(String userId) async {
    return _dailyUsageRepository.getTodaysUsage(userId);
  }

  void clearCache() {
    _cachedIsPremium = null;
    _cachedUserId = null;
    _dailyUsageRepository.clearCache();
  }

  void dispose() {
    _premiumSubscription?.cancel();
    _purchaseService.dispose();
  }
}
