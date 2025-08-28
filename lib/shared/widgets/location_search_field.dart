import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/location_service.dart';

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final String? errorText;
  final Function(LocationData)? onLocationSelected;
  final VoidCallback? onLocationDetected;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    this.errorText,
    this.onLocationSelected,
    this.onLocationDetected,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  
  List<LocationData> _searchResults = [];
  bool _isSearching = false;
  bool _isDetectingLocation = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _scrollController.dispose();
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    
    if (query.isEmpty) {
      _removeOverlay();
      return;
    }

    if (query != _lastQuery && query.length >= 2) {
      _lastQuery = query;
      _searchPlaces(query);
    }
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      // Delay removal to allow for selection
      Future.delayed(const Duration(milliseconds: 150), () {
        _removeOverlay();
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await LocationService.instance.searchPlaces(query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        if (results.isNotEmpty && widget.focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - (AppDimensions.screenPaddingHorizontal * 2),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 60.0),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                child: _buildSearchResults(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.all(AppDimensions.paddingM),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Text(
          'No locations found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: _searchResults.length > 3,
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingXS),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: AppColors.lightGray,
          indent: AppDimensions.paddingL + AppDimensions.iconS + AppDimensions.spacing8,
          endIndent: AppDimensions.paddingM,
        ),
        itemBuilder: (context, index) {
          final location = _searchResults[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectLocation(location),
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingM,
                  vertical: AppDimensions.paddingS,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: AppDimensions.iconS,
                    ),
                    const SizedBox(width: AppDimensions.spacing8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            location.displayLocation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (location.country.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              location.country,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectLocation(LocationData location) {
    widget.controller.text = location.displayLocation;
    widget.onLocationSelected?.call(location);
    _removeOverlay();
    widget.focusNode.unfocus();
    HapticFeedback.lightImpact();
  }

  Future<void> _detectCurrentLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
    });

    HapticFeedback.lightImpact();

    try {
      final result = await LocationService.instance.getCurrentPosition();
      
      if (mounted) {
        if (result.success && result.data != null) {
          widget.controller.text = result.data!.displayLocation;
          widget.onLocationSelected?.call(result.data!);
          widget.onLocationDetected?.call();
          
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.white, size: 20),
                  const SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: Text(
                      'Location detected: ${result.data!.displayLocation}',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Show error with action button for settings if permission is permanently denied
          final isPermissionError = result.error?.contains('permanently denied') == true ||
                                   result.error?.contains('device settings') == true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.white, size: 20),
                  const SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: Text(
                      result.error ?? 'Failed to detect location',
                      style: const TextStyle(color: AppColors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              duration: Duration(seconds: isPermissionError ? 5 : 3),
              action: isPermissionError
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: AppColors.white,
                      onPressed: () {
                        // This will open the app settings
                        // Note: You might need to add url_launcher package for this
                        // For now, we'll just show a hint
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please go to Settings > Privacy & Security > Location Services to enable location access.'),
                            backgroundColor: AppColors.info,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            ),
          );
        }
        
        setState(() {
          _isDetectingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.white, size: 20),
                const SizedBox(width: AppDimensions.spacing8),
                Expanded(
                  child: Text(
                    'Failed to detect location: $e',
                    style: const TextStyle(color: AppColors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textInputAction: TextInputAction.done,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            errorText: widget.errorText,
            labelText: widget.labelText,
            hintText: widget.hintText,
            filled: true,
            fillColor: isFocused ? AppColors.white : AppColors.lightGray,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(right: AppDimensions.spacing8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                  icon: _isDetectingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: AppDimensions.iconS,
                        ),
                  tooltip: 'Detect current location',
                ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
