import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/data/repositories/stats_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../data/services/profile_view_service.dart';
import 'paywall_screen.dart';

class WhoViewedMeScreen extends StatefulWidget {
  const WhoViewedMeScreen({super.key});

  @override
  State<WhoViewedMeScreen> createState() => _WhoViewedMeScreenState();
}

class _WhoViewedMeScreenState extends State<WhoViewedMeScreen> {
  final ProfileViewService _profileViewService = ProfileViewService();
  final StatsRepository _statsRepository = StatsRepository();
  final ProfileRepository _profileRepository = ProfileRepository();

  bool _isLoading = true;
  bool _isPremium = false;
  List<_ViewerInfo> _viewers = [];
  int _viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState.status != AuthStatus.authenticated) return;

    final userId = authState.user.id;

    try {
      final stats = await _statsRepository.getUserStats(userId);
      final premium = stats?.isPremium ?? false;
      final count = await _profileViewService.getViewerCount(userId);

      List<_ViewerInfo> viewers = [];
      if (premium) {
        final viewData = await _profileViewService.getViewers(userId, limit: 30);
        // Deduplicate by viewerId (keep most recent)
        final seen = <String>{};
        for (final view in viewData) {
          if (seen.contains(view.viewerId)) continue;
          seen.add(view.viewerId);

          final profile = await _profileRepository.getProfile(view.viewerId);
          if (profile != null) {
            viewers.add(_ViewerInfo(
              name: '${profile.firstName} ${profile.lastName}',
              photoUrl: profile.mainPhotoUrl,
              timestamp: view.timestamp,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _isPremium = premium;
          _viewers = viewers;
          _viewerCount = count;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
        ),
        title: Text(
          'Who Viewed You',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : _isPremium
              ? _buildViewersList()
              : _buildLockedState(),
    );
  }

  Widget _buildViewersList() {
    if (_viewers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimensions.spacing16),
            Text(
              'No profile views yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            Text(
              'When someone views your profile, they\'ll appear here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      itemCount: _viewers.length,
      itemBuilder: (context, index) {
        final viewer = _viewers[index];
        return _buildViewerTile(viewer);
      },
    );
  }

  Widget _buildViewerTile(_ViewerInfo viewer) {
    final timeAgo = _formatTimeAgo(viewer.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightGray,
            backgroundImage: viewer.photoUrl != null && viewer.photoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(viewer.photoUrl!)
                : null,
            child: viewer.photoUrl == null || viewer.photoUrl!.isEmpty
                ? const Icon(Icons.person, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewer.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  'Viewed your profile $timeAgo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.visibility,
            color: AppColors.primary,
            size: AppDimensions.iconS,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedState() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
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
              Icons.lock,
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          Text(
            '$_viewerCount people viewed your profile',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            'Upgrade to Pro to see who\'s been checking you out',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacing32),
          // Blurred preview tiles
          ...List.generate(3, (index) => _buildBlurredTile()),
          const SizedBox(height: AppDimensions.spacing32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                PaywallScreen.show(context, PaywallTrigger.whoViewedMe);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingL,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                ),
              ),
              child: const Text(
                'Upgrade to Pro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurredTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacing12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.lightGray,
                  child: Icon(Icons.person, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppDimensions.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}

class _ViewerInfo {
  final String name;
  final String? photoUrl;
  final DateTime timestamp;

  _ViewerInfo({
    required this.name,
    this.photoUrl,
    required this.timestamp,
  });
}
