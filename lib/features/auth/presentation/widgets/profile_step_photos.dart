import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class ProfileStepPhotos extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(String, dynamic) onDataChanged;

  const ProfileStepPhotos({
    super.key,
    required this.profileData,
    required this.onDataChanged,
  });

  @override
  State<ProfileStepPhotos> createState() => _ProfileStepPhotosState();
}

class _ProfileStepPhotosState extends State<ProfileStepPhotos>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late List<Animation<Offset>> _photoAnimations;

  final int _maxPhotos = 6;
  final List<GlobalKey<_PhotoCardState>> _cardKeys = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCardKeys();
    _startAnimations();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create staggered animations for photo slots
    _photoAnimations = List.generate(_maxPhotos, (index) {
      final startTime = (index * 0.1).clamp(0.0, 0.5);
      final endTime = (0.6 + (index * 0.1)).clamp(startTime + 0.1, 1.0);

      return Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Interval(
          startTime,
          endTime,
          curve: Curves.easeOutCubic,
        ),
      ));
    });
  }

  void _initializeCardKeys() {
    _cardKeys.clear();
    for (int i = 0; i < _maxPhotos; i++) {
      _cardKeys.add(GlobalKey<_PhotoCardState>());
    }
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _slideController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onPhotoChanged() {
    // Collect all photos from individual cards
    final photoList = <String>[];
    for (final key in _cardKeys) {
      final cardState = key.currentState;
      if (cardState != null && cardState.hasPhoto) {
        photoList.add(cardState.photoFile!.path);
      }
    }
    widget.onDataChanged('photos', photoList);
  }

  void _makeMainPhoto(int index) {
    if (index == 0) return;

    final currentMainCard = _cardKeys[0].currentState;
    final selectedCard = _cardKeys[index].currentState;

    if (currentMainCard != null &&
        selectedCard != null &&
        selectedCard.hasPhoto) {
      final mainPhoto = currentMainCard.photoFile;
      final selectedPhoto = selectedCard.photoFile;

      // Swap photos
      currentMainCard.setPhoto(selectedPhoto);
      selectedCard.setPhoto(mainPhoto);

      _onPhotoChanged();
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingHorizontal,
      ),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.spacing24),

          // Photo Grid
          _buildPhotoGrid(),

          const SizedBox(height: AppDimensions.spacing32),

          // Upload Instructions
          _buildInstructions(),

          const SizedBox(height: AppDimensions.spacing32),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      key: const ValueKey('photo_grid'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppDimensions.spacing12,
        mainAxisSpacing: AppDimensions.spacing12,
        childAspectRatio: 0.75,
      ),
      itemCount: _maxPhotos,
      itemBuilder: (context, index) {
        return SlideTransition(
          position: _photoAnimations[index],
          child: PhotoCard(
            key: _cardKeys[index],
            index: index,
            onPhotoChanged: _onPhotoChanged,
            onMakeMain: () => _makeMainPhoto(index),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Text(
                'Photo Tips',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _buildTip('📸', 'First photo will be your main profile picture'),
          const SizedBox(height: AppDimensions.spacing8),
          _buildTip('😊', 'Use clear, recent photos that show your face'),
          const SizedBox(height: AppDimensions.spacing8),
          _buildTip('🌟', 'Show your personality and interests'),
          const SizedBox(height: AppDimensions.spacing8),
          _buildTip('⛪', 'Include photos from church or faith activities'),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ),
      ],
    );
  }
}

// Individual Photo Card Widget
class PhotoCard extends StatefulWidget {
  final int index;
  final VoidCallback onPhotoChanged;
  final VoidCallback onMakeMain;

  const PhotoCard({
    super.key,
    required this.index,
    required this.onPhotoChanged,
    required this.onMakeMain,
  });

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  final ImagePicker _picker = ImagePicker();
  XFile? _photoFile;
  bool _isLoading = false;

  bool get hasPhoto => _photoFile != null;
  XFile? get photoFile => _photoFile;

  void setPhoto(XFile? photo) {
    if (mounted) {
      setState(() {
        _photoFile = photo;
      });
    }
  }

  void _addPhoto() async {
    if (_isLoading) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _photoFile = image;
          _isLoading = false;
        });

        widget.onPhotoChanged();
        HapticFeedback.mediumImpact();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to add photo. Please try again.');
    }
  }

  void _removePhoto() {
    HapticFeedback.mediumImpact();
    setState(() {
      _photoFile = null;
    });
    widget.onPhotoChanged();
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusL),
            topRight: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppDimensions.spacing8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              if (widget.index != 0)
                ListTile(
                  leading:
                      const Icon(Icons.star_outline, color: AppColors.primary),
                  title: const Text('Set as main photo'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onMakeMain();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Replace photo'),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
              const SizedBox(height: AppDimensions.spacing16),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasPhoto ? _showPhotoOptions : _addPhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: hasPhoto ? Colors.transparent : AppColors.lightGray,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: hasPhoto ? Colors.transparent : AppColors.border,
            width: 2,
            style: hasPhoto ? BorderStyle.none : BorderStyle.solid,
          ),
        ),
        child: hasPhoto ? _buildPhotoContainer() : _buildEmptySlot(),
      ),
    );
  }

  Widget _buildPhotoContainer() {
    return Stack(
      children: [
        // Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _isLoading
                ? Container(
                    color: AppColors.lightGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    child: kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _photoFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                );
                              }
                              return Container(
                                color: AppColors.lightGray,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Image.file(
                            File(_photoFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
          ),
        ),

        // Main photo indicator
        if (widget.index == 0)
          Positioned(
            top: AppDimensions.spacing8,
            left: AppDimensions.spacing8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing8,
                vertical: AppDimensions.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: AppDimensions.spacing4),
                  Text(
                    'Main',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),

        // Remove button
        Positioned(
          top: AppDimensions.spacing8,
          right: AppDimensions.spacing8,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),

        // Gradient overlay for better button visibility
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.1),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySlot() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  widget.index == 0 ? 'Main Photo' : 'Add Photo',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
    );
  }
}
