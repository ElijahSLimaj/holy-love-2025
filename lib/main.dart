import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/profile_creation_screen.dart';
import 'features/main/presentation/pages/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HolyLoveApp());
}

class HolyLoveApp extends StatelessWidget {
  const HolyLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
        child: MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AppView(),
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return _AppNavigator(authState: state);
      },
    );
  }
}

class _AppNavigator extends StatelessWidget {
  const _AppNavigator({required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    switch (authState.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.loading:
        return const SplashScreen();
      case AuthStatus.authenticated:
        // Check if user needs onboarding
        if (authState.user.isNewUser) {
          // Navigate to profile creation/onboarding
          return const ProfileCreationScreen();
        } else {
          // Navigate to main app
          return const MainNavigationScreen();
        }
    }
  }
}
