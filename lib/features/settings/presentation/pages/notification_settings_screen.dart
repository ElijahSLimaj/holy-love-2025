import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // Notification settings
  bool _newMatches = true;
  bool _messages = true;
  bool _likes = true;
  bool _profileViews = false;
  bool _faithConnections = true;
  bool _prayerRequests = true;
  bool _bibleVerses = true;
  bool _communityEvents = false;
  bool _premiumFeatures = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _headerController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
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
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          decoration: BoxDecoration(
            gradient: AppColors.loveGradient,
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacing8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing16),
                  const Expanded(
                    child: Text(
                      'Notification Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Text(
                'Customize how you receive notifications about your faith journey',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SlideTransition(
      position: _contentSlideAnimation,
      child: FadeTransition(
        opacity: _contentFadeAnimation,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          children: [
            _buildSection(
              title: 'Connection Notifications',
              icon: Icons.favorite,
              children: [
                _buildSwitchTile(
                  title: 'New Matches',
                  subtitle: 'When someone new matches with you',
                  value: _newMatches,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _newMatches = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Messages',
                  subtitle: 'When you receive new messages',
                  value: _messages,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _messages = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Likes',
                  subtitle: 'When someone likes your profile',
                  value: _likes,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _likes = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Profile Views',
                  subtitle: 'When someone views your profile',
                  value: _profileViews,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _profileViews = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'Faith & Community',
              icon: Icons.church,
              children: [
                _buildSwitchTile(
                  title: 'Faith Connections',
                  subtitle: 'When someone shares their faith journey',
                  value: _faithConnections,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _faithConnections = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Prayer Requests',
                  subtitle: 'When someone shares a prayer request',
                  value: _prayerRequests,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _prayerRequests = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Bible Verses',
                  subtitle: 'Daily Bible verse notifications',
                  value: _bibleVerses,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _bibleVerses = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Community Events',
                  subtitle: 'Local faith community events',
                  value: _communityEvents,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _communityEvents = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'App & Premium',
              icon: Icons.star,
              children: [
                _buildSwitchTile(
                  title: 'Premium Features',
                  subtitle: 'New premium features and updates',
                  value: _premiumFeatures,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _premiumFeatures = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'Notification Preferences',
              icon: Icons.settings,
              children: [
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications on your device',
                  value: _pushNotifications,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _pushNotifications = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: _emailNotifications,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _emailNotifications = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sound for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _soundEnabled = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _vibrationEnabled = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing32),
            _buildSaveButton(),
            const SizedBox(height: AppDimensions.spacing24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              gradient: AppColors.loveGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusL),
                topRight: Radius.circular(AppDimensions.radiusL),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                gradient: value ? AppColors.loveGradient : null,
                color: value ? null : AppColors.lightGray,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: value ? 22 : 2,
                    top: 2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Settings',
      onPressed: () {
        HapticFeedback.mediumImpact();
        // TODO: Save notification settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification settings saved!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      },
      variant: ButtonVariant.primary,
      size: ButtonSize.large,
    );
  }
} 