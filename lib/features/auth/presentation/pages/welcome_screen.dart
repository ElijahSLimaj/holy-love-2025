import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../bloc/auth_bloc.dart';
import '../../../main/presentation/pages/main_navigation_screen.dart';

import 'sign_up_screen.dart';
import 'sign_in_screen.dart';
import 'profile_creation_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            AppSnackbar.showError(
              context,
              message: state.errorMessage!,
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.lightGray,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingHorizontal,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Hero Section
                  _buildHeroSection(context),
                  
                  const Spacer(flex: 3),
                  
                  // Action Buttons
                  _buildActionButtons(context),
                  
                  const SizedBox(height: AppDimensions.spacing32),
                  
                  // Sign In Link
                  _buildSignInLink(context),
                  
                  const SizedBox(height: AppDimensions.spacing24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: AppColors.cardShadow,
          ),
          child: const Icon(
            Icons.favorite,
            size: 50,
            color: AppColors.primary,
          ),
        ),
        
        const SizedBox(height: AppDimensions.spacing32),
        
        // Welcome Text
        Text(
          AppStrings.welcome,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppDimensions.spacing16),
        
        // Welcome Message
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
          ),
          child: Text(
            AppStrings.welcomeMessage,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Get Started Button
        CustomButton(
          text: AppStrings.getStarted,
          onPressed: () => _navigateToSignUp(context),
          variant: ButtonVariant.primary,
        ),
        
        const SizedBox(height: AppDimensions.spacing16),
        
        // Continue with Google
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state.status == AuthStatus.loading;
            return CustomButton(
              text: AppStrings.continueWithGoogle,
              onPressed: isLoading 
                  ? null 
                  : () => context.read<AuthBloc>().add(
                        const AuthSignInWithGoogleRequested(),
                      ),
              variant: ButtonVariant.socialGradientBorder,
              isLoading: isLoading,
              icon: isLoading
                  ? null
                  : SvgPicture.asset(
                      'assets/images/svg/google-icon.svg',
                      width: AppDimensions.iconM,
                      height: AppDimensions.iconM,
                    ),
            );
          },
        ),
        
        const SizedBox(height: AppDimensions.spacing12),
        
        // Continue with Apple
        CustomButton(
          text: AppStrings.continueWithApple,
          onPressed: () {
            // TODO: Implement Apple sign in
            AppSnackbar.showInfo(
              context,
              message: '🍎 Apple Sign-In is coming soon! We\'re working on it.',
            );
          },
          variant: ButtonVariant.socialGradientBorder,
          icon: SvgPicture.asset(
            'assets/images/svg/apple-icon.svg',
            width: AppDimensions.iconM,
            height: AppDimensions.iconM,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.alreadyHaveAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing8),
        TextButton(
          onPressed: () => _navigateToSignIn(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.signIn,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToSignUp(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToSignIn(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignInScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
} 