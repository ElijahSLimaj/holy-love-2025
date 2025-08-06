import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../profile/presentation/bloc/profile_creation_bloc.dart';

class ProfileStepBasicInfo extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final Function(String, dynamic) onDataChanged;
  final VoidCallback? onStepCompleted;

  const ProfileStepBasicInfo({
    super.key,
    required this.profileData,
    required this.onDataChanged,
    this.onStepCompleted,
  });

  @override
  State<ProfileStepBasicInfo> createState() => ProfileStepBasicInfoState();
}

class ProfileStepBasicInfoState extends State<ProfileStepBasicInfo>
    with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _locationFocusNode = FocusNode();
  
  late AnimationController _slideController;
  late List<Animation<Offset>> _fieldAnimations;
  
  // Form validation
  final _formKey = GlobalKey<FormState>();
  Map<String, String> _fieldErrors = {};
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadExistingData();
    _setupListeners();
    _startAnimations();
  }
  
  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create staggered animations for each field
    _fieldAnimations = List.generate(4, (index) {
      final startTime = (index * 0.1).clamp(0.0, 0.6);
      final endTime = (0.4 + (index * 0.1)).clamp(startTime + 0.1, 1.0);
      
      return Tween<Offset>(
        begin: const Offset(0, 0.3),
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
  
  void _loadExistingData() {
    _firstNameController.text = widget.profileData['firstName'] ?? '';
    _lastNameController.text = widget.profileData['lastName'] ?? '';
    _ageController.text = widget.profileData['age']?.toString() ?? '';
    _locationController.text = widget.profileData['location'] ?? '';
  }
  
  void _setupListeners() {
    _firstNameController.addListener(() {
      widget.onDataChanged('firstName', _firstNameController.text);
    });
    
    _lastNameController.addListener(() {
      widget.onDataChanged('lastName', _lastNameController.text);
    });
    
    _ageController.addListener(() {
      final age = int.tryParse(_ageController.text);
      widget.onDataChanged('age', age);
    });
    
    _locationController.addListener(() {
      widget.onDataChanged('location', _locationController.text);
    });
    
    // Focus listeners for animations
    _firstNameFocusNode.addListener(() => setState(() {}));
    _lastNameFocusNode.addListener(() => setState(() {}));
    _ageFocusNode.addListener(() => setState(() {}));
    _locationFocusNode.addListener(() => setState(() {}));
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _ageFocusNode.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileCreationBloc, ProfileCreationState>(
      listener: (context, state) {
        if (state is ProfileCreationError) {
          // Update field errors
          setState(() {
            _fieldErrors = state.fieldErrors ?? {};
          });
          
          // Show error snackbar if general error
          if (state.fieldErrors == null || state.fieldErrors!.isEmpty) {
            _showErrorSnackBar(state.message);
          }
        } else if (state is ProfileCreationStepCompleted) {
          // Clear errors and notify parent
          setState(() {
            _fieldErrors = {};
          });
          widget.onStepCompleted?.call();
        }
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingHorizontal,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppDimensions.spacing24),
              
              // First Name Field
              SlideTransition(
                position: _fieldAnimations[0],
                child: _buildAnimatedTextField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocusNode,
                  labelText: AppStrings.firstName,
                  hintText: 'Enter your first name',
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _lastNameFocusNode.requestFocus(),
                  errorText: _fieldErrors['firstName'],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'First name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'First name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
              ),
          
          const SizedBox(height: AppDimensions.spacing20),
          
          // Last Name Field
          SlideTransition(
            position: _fieldAnimations[1],
            child: _buildAnimatedTextField(
              controller: _lastNameController,
              focusNode: _lastNameFocusNode,
              labelText: AppStrings.lastName,
              hintText: 'Enter your last name',
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _ageFocusNode.requestFocus(),
              errorText: _fieldErrors['lastName'],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required';
                }
                if (value.trim().length < 2) {
                  return 'Last name must be at least 2 characters';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing20),
          
          // Age Field
          SlideTransition(
            position: _fieldAnimations[2],
            child: _buildAnimatedTextField(
              controller: _ageController,
              focusNode: _ageFocusNode,
              labelText: AppStrings.age,
              hintText: 'Enter your age',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onFieldSubmitted: (_) => _locationFocusNode.requestFocus(),
              errorText: _fieldErrors['age'],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Age is required';
                }
                final age = int.tryParse(value);
                if (age == null) {
                  return 'Please enter a valid age';
                }
                if (age < 18) {
                  return 'You must be at least 18 years old';
                }
                if (age > 100) {
                  return 'Please enter a valid age';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing20),
          
          // Location Field
          SlideTransition(
            position: _fieldAnimations[3],
            child: _buildAnimatedTextField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              labelText: AppStrings.location,
              hintText: 'City, State',
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                onPressed: _detectLocation,
                icon: const Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                  size: AppDimensions.iconS,
                ),
              ),
              errorText: _fieldErrors['location'],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Location is required';
                }
                return null;
              },
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacing32),
          
          // Info Card
          SlideTransition(
            position: _fieldAnimations[3],
            child: _buildInfoCard(),
          ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required String hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? errorText,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;
    
    return AnimatedContainer(
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
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          errorText: errorText,
          labelText: labelText,
          hintText: hintText,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isFocused 
              ? AppColors.white 
              : AppColors.lightGray,
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
    );
  }
  
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppColors.primary,
              size: AppDimensions.iconS,
            ),
          ),
          const SizedBox(width: AppDimensions.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Information',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing4),
                Text(
                  'This information will be visible on your profile to help others get to know you.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _detectLocation() async {
    // TODO: Implement location detection
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Location detection coming soon!'),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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

  /// Save basic info data to Firestore
  Future<void> saveBasicInfo() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    // Extract location components if available
    final locationParts = _locationController.text.split(',').map((e) => e.trim()).toList();
    final locationCity = locationParts.isNotEmpty ? locationParts[0] : null;
    final locationState = locationParts.length > 1 ? locationParts[1] : null;

    // Save to Firestore via bloc
    context.read<ProfileCreationBloc>().add(
      SaveBasicInfoRequested(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text),
        location: _locationController.text.trim(),
        locationCity: locationCity,
        locationState: locationState,
      ),
    );
  }
} 