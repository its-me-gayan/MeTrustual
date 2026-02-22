import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/providers/firebase_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _barController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _barController.forward();
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _fadeController.forward().then((_) async {
          final auth = ref.read(firebaseAuthProvider);
          final user = auth.currentUser;

          if (user != null) {
            final biometricSetUp = await BiometricService.isBiometricSetUp();
            if (!biometricSetUp) {
              context.go('/biometric-setup/${user.uid}');
              return;
            }

            // Route to PIN verification screen instead of using dialogs
            context.go('/pin-verification');
            return;
          }

          // Not logged in
          context.go('/onboarding');
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF0F0),
                Color(0xFFFDE8F0),
                Color(0xFFF0E8FC),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.07).animate(
                    CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.cycleCircleGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRose.withOpacity(0.3),
                          blurRadius: 36,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🌸', style: TextStyle(fontSize: 45)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
                    CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
                  ),
                  child: FadeTransition(
                    opacity: _slideController,
                    child: const Text(
                      'MeTrustual',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
