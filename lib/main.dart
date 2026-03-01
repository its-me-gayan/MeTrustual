import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/premium_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Init RevenueCat. If user is already signed in, link their uid immediately
  // so any purchases they made are associated with their account from launch.
  final currentUser = FirebaseAuth.instance.currentUser;
  await PremiumService.init(uid: currentUser?.uid);

  // Start real-time entitlement listener for signed-in non-anonymous users.
  // This fires whenever the store reports a change (renewal, expiry, refund)
  // and writes the result to Firestore, which premiumStatusProvider reacts to.
  if (currentUser != null && !currentUser.isAnonymous) {
    PremiumService.startListening(
      uid: currentUser.uid,
      firestore: FirebaseFirestore.instance,
    );
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ms'),
        Locale('es'),
        Locale('hi'),
        Locale('ar'),
      ],
      path: 'assets/l10n',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(
        child: MeTrustualApp(),
      ),
    ),
  );
}

class MeTrustualApp extends StatefulWidget {
  const MeTrustualApp({super.key});

  @override
  State<MeTrustualApp> createState() => _MeTrustualAppState();
}

// ── App-level lifecycle observer ─────────────────────────────────────────────
//
// Re-verifies premium status every time the app comes back to the foreground.
// This catches the key scenario: user cancels subscription from device Settings
// or App Store, then returns to the app — access is revoked immediately.
class _MeTrustualAppState extends State<MeTrustualApp>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    // Re-verify from store on every foreground resume.
    // Silent — no loading indicator, just syncs Firestore in background.
    await PremiumService.verifyAndSync(
      uid: user.uid,
      firestore: FirebaseFirestore.instance,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MeTrustual',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
