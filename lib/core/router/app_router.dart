import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/biometric_setup_screen.dart';
import '../../features/onboarding/screens/mode_selection_screen.dart';
import '../../features/onboarding/screens/journey_screen.dart';
import '../../features/onboarding/screens/pin_verification_screen.dart';
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/signup_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/logging/screens/log_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/education/screens/education_screen.dart';
import '../../features/privacy/screens/privacy_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/premium_screen.dart';
import '../../features/care/screens/self_care_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) {
        final isPremium = state.uri.queryParameters['premium'] == 'true';
        return SignupScreen(isPremiumFlow: isPremium);
      },
    ),
    GoRoute(
      path: '/biometric-setup/:uid',
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        return BiometricSetupScreen(uid: uid);
      },
    ),
    GoRoute(
      path: '/pin-verification',
      builder: (context, state) => const PinVerificationScreen(),
    ),
    GoRoute(
      path: '/mode-selection',
      builder: (context, state) => const ModeSelectionScreen(),
    ),
    GoRoute(
      path: '/journey/:mode',
      builder: (context, state) {
        final mode = state.pathParameters['mode'] ?? 'period';
        return JourneyScreen(mode: mode);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/log',
      builder: (context, state) => const LogScreen(),
    ),
    GoRoute(
      path: '/insights',
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: '/education',
      builder: (context, state) => const EducationScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/care',
      builder: (context, state) => const SelfCareScreen(),
    ),
  ],
);
