import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/config/mapbox_config.dart';
import 'core/services/location_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/profile_creation_screen.dart';
import 'features/main/presentation/pages/main_navigation_screen.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_creation_bloc.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
  // Process background notification if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize(navigatorKey: navigatorKey);

  // Initialize location service
  if (MapboxConfig.isConfigured) {
    await LocationService.instance.initialize(
      mapboxToken: MapboxConfig.activeApiKey,
    );
  }

  runApp(const HolyLoveApp());
}

class HolyLoveApp extends StatelessWidget {
  const HolyLoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => ProfileRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ProfileCreationBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const AppView(),
        ),
      ),
    );
  }
}

class AppView extends StatefulWidget {
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> with WidgetsBindingObserver {
  final PresenceService _presenceService = PresenceService();
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isAuthenticated) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _presenceService.setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _presenceService.setAway();
        break;
      case AppLifecycleState.detached:
        _presenceService.setOffline();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final wasAuthenticated = _isAuthenticated;
        _isAuthenticated = state.status == AuthStatus.authenticated;

        if (_isAuthenticated && !wasAuthenticated) {
          _presenceService.setOnline();
          _presenceService.startHeartbeat();
        } else if (!_isAuthenticated && wasAuthenticated) {
          _presenceService.setOffline();
        }

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
