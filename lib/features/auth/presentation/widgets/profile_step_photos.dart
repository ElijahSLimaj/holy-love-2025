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
  final ImagePicker _picker = ImagePicker();
  List<XFile?> _photoFiles = [];
  Set<int> _loadingPhotos = {};
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late List<Animation<Offset>> _photoAnimations;
  
  final int _maxPhotos = 6;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingPhotos();
    _startAnimations();
  }
  
  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
  
  void _loadExistingPhotos() {
    // Always initialize with 6 slots
    _photoFiles = List.generate(_maxPhotos, (index) => null);
    
    final photos = widget.profileData['photos'] as List<String>?;
    if (photos != null && photos.isNotEmpty) {
      // TODO: Convert saved photo paths back to XFile objects if needed
      // For now, we'll start fresh each time the user returns to this step
      setState(() {
        _loadingPhotos.clear();
      });
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
    _scaleController.dispose();
    super.dispose();
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
      key: const ValueKey('photo_grid'), // Add key to prevent rebuilds
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
          key: ValueKey('photo_slot_$index'),
          position: _photoAnimations[index],
          child: _buildPhotoSlot(index),
        );
      },
    );
  }
  
  Widget _buildPhotoSlot(int index) {
    final hasPhoto = _photoFiles[index] != null;
    
    return GestureDetector(
      key: ValueKey('photo_gesture_$index'),
      onTap: () => hasPhoto ? _showPhotoOptions(index) : _addPhotoToSlot(index),
      child: AnimatedContainer(
        key: ValueKey('photo_container_$index'),
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
        child: hasPhoto ? _buildPhotoContainer(index) : _buildEmptySlot(index),
      ),
    );
  }
  
  Widget _buildPhotoContainer(int index) {
    final isLoading = _loadingPhotos.contains(index);
    final photoFile = _photoFiles[index];
    
    return Stack(
      key: ValueKey('photo_stack_$index'),
      children: [
        // Photo
        ClipRRect(
          key: ValueKey('photo_clip_$index'),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          child: Container(
            key: ValueKey('photo_content_$index'),
            width: double.infinity,
            height: double.infinity,
            child: isLoading 
                ? Container(
                    color: AppColors.lightGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : photoFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: photoFile.readAsBytes(),
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
                                File(photoFile.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.lightGray,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: AppColors.textTertiary,
                                      size: 32,
                                    ),
                                  );
                                },
                              ),
                      )
                    : Container(
                        color: AppColors.lightGray,
                        child: const Icon(
                          Icons.photo,
                          color: AppColors.textTertiary,
                          size: 32,
                        ),
                      ),
          ),
        ),
        
        // Overlay for better button visibility
        if (!isLoading && photoFile != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3],
                ),
              ),
            ),
          ),
        
        // Primary badge (for first photo)
        if (index == 0)
          Positioned(
            top: AppDimensions.spacing8,
            left: AppDimensions.spacing8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing8,
                vertical: AppDimensions.spacing4,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.loveGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Text(
                'Main',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        
        // Remove button
        if (!isLoading && photoFile != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 6,
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
          ),
      ],
    );
  }
  
  Widget _buildEmptySlot(int index) {
    final isFirst = index == 0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.spacing12),
          decoration: BoxDecoration(
            color: isFirst 
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.gray.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isFirst ? Icons.camera_alt : Icons.add_photo_alternate,
            color: isFirst ? AppColors.primary : AppColors.gray,
            size: AppDimensions.iconL,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Text(
          isFirst ? 'Main Photo' : 'Add Photo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isFirst ? AppColors.primary : AppColors.textTertiary,
            fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildInstructions() {
    return SlideTransition(
      position: _photoAnimations[5],
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tips_and_updates,
                    color: AppColors.accent,
                    size: AppDimensions.iconS,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Text(
                    'Photo Tips',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            _buildTip('📸', 'Tap empty slots above to add photos'),
            const SizedBox(height: AppDimensions.spacing8),
            _buildTip('😊', 'Choose photos that show your face clearly'),
            const SizedBox(height: AppDimensions.spacing8),
            _buildTip('🌟', 'Show your personality and interests'),
            const SizedBox(height: AppDimensions.spacing8),
            _buildTip('⛪', 'Include photos from church or faith activities'),
          ],
        ),
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
  

  
  // Photo management methods
  void _addPhotoToSlot(int targetIndex) async {
    if (_photoFiles[targetIndex] != null || _loadingPhotos.contains(targetIndex)) return;
    
    HapticFeedback.lightImpact();
    
    // Show loading state
    setState(() {
      _loadingPhotos.add(targetIndex);
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
          _photoFiles[targetIndex] = image;
          _loadingPhotos.remove(targetIndex);
        });
        
        // Update parent data
        final photoList = _photoFiles.where((file) => file != null).map((file) => file!.path).toList();
        widget.onDataChanged('photos', photoList);
        
        // Show success feedback
        HapticFeedback.mediumImpact();
      } else {
        // User cancelled, remove loading state
        setState(() {
          _loadingPhotos.remove(targetIndex);
        });
      }
    } catch (e) {
      // Remove loading state on error
      setState(() {
        _loadingPhotos.remove(targetIndex);
      });
      _showErrorSnackBar('Failed to add photo. Please try again.');
    }
  }


  
  void _removePhoto(int index) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      _photoFiles[index] = null; // Set to null instead of removing
      _loadingPhotos.remove(index);
    });
    
    final photoList = _photoFiles.where((file) => file != null).map((file) => file!.path).toList();
    widget.onDataChanged('photos', photoList);
  }
  
  void _showPhotoOptions(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppDimensions.spacing8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing24),
            
            ListTile(
              leading: const Icon(Icons.star, color: AppColors.accent),
              title: const Text('Make Main Photo'),
              onTap: () {
                _makeMainPhoto(index);
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Replace Photo'),
              onTap: () {
                Navigator.pop(context);
                _replacePhoto(index);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: Text(
                'Remove Photo',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _removePhoto(index);
              },
            ),
            
            const SizedBox(height: AppDimensions.spacing24),
          ],
        ),
      ),
    );
  }
  
  void _makeMainPhoto(int index) {
    if (index == 0 || _photoFiles[index] == null) return;
    
    setState(() {
      final photo = _photoFiles[index];
      final currentMain = _photoFiles[0];
      _photoFiles[0] = photo;
      _photoFiles[index] = currentMain;
    });
    
    final photoList = _photoFiles.where((file) => file != null).map((file) => file!.path).toList();
    widget.onDataChanged('photos', photoList);
    HapticFeedback.lightImpact();
  }
  
  void _replacePhoto(int index) async {
    // Show loading state
    setState(() {
      _loadingPhotos.add(index);
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
          _photoFiles[index] = image;
          _loadingPhotos.remove(index);
        });
        
        final photoList = _photoFiles.where((file) => file != null).map((file) => file!.path).toList();
        widget.onDataChanged('photos', photoList);
        HapticFeedback.mediumImpact();
      } else {
        // User cancelled, remove loading state
        setState(() {
          _loadingPhotos.remove(index);
        });
      }
    } catch (e) {
      // Remove loading state on error
      setState(() {
        _loadingPhotos.remove(index);
      });
      _showErrorSnackBar('Failed to replace photo. Please try again.');
    }
  }
  
  void _showErrorSnackBar(String message) {
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
} 