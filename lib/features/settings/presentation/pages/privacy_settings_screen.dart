import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  // Privacy settings
  bool _profileVisibility = true;
  bool _showOnlineStatus = true;
  bool _showLastSeen = false;
  bool _showDistance = true;
  bool _showAge = true;
  bool _showOccupation = true;
  bool _showDenomination = true;
  bool _allowMessagesFromEveryone = true;
  bool _allowLikesFromEveryone = true;
  bool _showProfileToEveryone = true;
  bool _dataCollection = true;
  bool _analytics = true;
  bool _personalizedAds = false;

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
                      'Privacy Settings',
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
                'Control who can see your profile and how your data is used',
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
              title: 'Profile Visibility',
              icon: Icons.visibility,
              children: [
                _buildSwitchTile(
                  title: 'Profile Visibility',
                  subtitle: 'Make your profile visible to other users',
                  value: _profileVisibility,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _profileVisibility = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Online Status',
                  subtitle: 'Let others see when you\'re online',
                  value: _showOnlineStatus,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showOnlineStatus = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Last Seen',
                  subtitle: 'Show when you were last active',
                  value: _showLastSeen,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showLastSeen = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'Profile Information',
              icon: Icons.person,
              children: [
                _buildSwitchTile(
                  title: 'Show Distance',
                  subtitle: 'Display your approximate location',
                  value: _showDistance,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showDistance = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Age',
                  subtitle: 'Display your age on your profile',
                  value: _showAge,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showAge = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Occupation',
                  subtitle: 'Display your occupation',
                  value: _showOccupation,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showOccupation = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Denomination',
                  subtitle: 'Display your faith denomination',
                  value: _showDenomination,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showDenomination = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'Communication',
              icon: Icons.message,
              children: [
                _buildSwitchTile(
                  title: 'Allow Messages from Everyone',
                  subtitle: 'Let anyone send you messages',
                  value: _allowMessagesFromEveryone,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _allowMessagesFromEveryone = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Allow Likes from Everyone',
                  subtitle: 'Let anyone like your profile',
                  value: _allowLikesFromEveryone,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _allowLikesFromEveryone = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Show Profile to Everyone',
                  subtitle: 'Make your profile discoverable by all users',
                  value: _showProfileToEveryone,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _showProfileToEveryone = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildSection(
              title: 'Data & Analytics',
              icon: Icons.analytics,
              children: [
                _buildSwitchTile(
                  title: 'Data Collection',
                  subtitle: 'Allow us to collect usage data to improve the app',
                  value: _dataCollection,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _dataCollection = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Analytics',
                  subtitle: 'Help us understand how you use the app',
                  value: _analytics,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _analytics = value);
                  },
                ),
                _buildSwitchTile(
                  title: 'Personalized Ads',
                  subtitle: 'Show ads based on your interests',
                  value: _personalizedAds,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() => _personalizedAds = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing24),
            _buildPrivacyActions(),
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

  Widget _buildPrivacyActions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
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
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                const Text(
                  'Privacy Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildActionTile(
            title: 'Download My Data',
            subtitle: 'Get a copy of all your data',
            icon: Icons.download,
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Implement data download
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Data download request submitted!'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              );
            },
          ),
          _buildActionTile(
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            icon: Icons.delete_forever,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showDeleteAccountDialog();
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing8),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : AppColors.textPrimary,
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
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomButton(
      text: 'Save Privacy Settings',
      onPressed: () {
        HapticFeedback.mediumImpact();
        // TODO: Save privacy settings
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Privacy settings saved!'),
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 