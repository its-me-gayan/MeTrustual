import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/providers/firebase_providers.dart';
import 'package:google_fonts/google_fonts.dart';

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

  final List<PetalModel> _petals = List.generate(15, (index) => PetalModel());
  final List<double> _ringDelays = [0.0, 0.7, 1.4];

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

    // Start bar and slide animations after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _slideController.forward();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _barController.forward();
        });
      }
    });

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _fadeController.forward().then((_) async {
          final auth = ref.read(firebaseAuthProvider);
          final user = auth.currentUser;

          print('═══════════════════════════════════════════');
          print('🔍 SPLASH SCREEN NAVIGATION LOGIC');
          print('═══════════════════════════════════════════');
          print('✓ user exists: ${user != null}');
          print('✓ user UID: ${user?.uid}');

          if (user == null) {
            print('➜ Route: /onboarding (no user)');
            print('═══════════════════════════════════════════');
            context.go('/onboarding');
            return;
          }

          final biometricSetUp = await BiometricService.isBiometricSetUp();
          print('✓ biometricSetUp flag: $biometricSetUp');

          if (biometricSetUp) {
            print('➜ Route: /pin-verification (ASK PIN)');
            print('═══════════════════════════════════════════');
            context.go('/pin-verification');
            return;
          }

          // Sync with Firestore to check journey status
          await ref.read(modeProvider.notifier).syncFromFirestore();
          final hasCompleted =
              ref.read(modeProvider.notifier).hasCompletedJourney;

          if (hasCompleted) {
            print('➜ Route: /home (journey completed)');
            print('═══════════════════════════════════════════');
            context.go('/home');
          } else {
            print('➜ Route: /onboarding (journey not completed)');
            print('═══════════════════════════════════════════');
            context.go('/onboarding');
          }
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
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
        ),
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(gradient: LinearGradient(
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
            child: Stack(
              children: [
                // Floating Petals
                ..._petals.map((petal) => FloatingPetal(petal: petal)),

                // Ripple Rings
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: _ringDelays
                        .map((delay) => RippleRing(delay: delay))
                        .toList(),
                  ),
                ),

                // Center Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Circle
                      ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.07).animate(
                          CurvedAnimation(
                              parent: _logoController, curve: Curves.easeInOut),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.cycleCircleGradient,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFCE8E8).withOpacity(0.5),
                                blurRadius: 0,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: AppColors.primaryRose.withOpacity(0.3),
                                blurRadius: 36,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: RotationTransition(
                            turns: Tween<double>(begin: -0.014, end: 0.014)
                                .animate(
                              CurvedAnimation(
                                  parent: _logoController,
                                  curve: Curves.easeInOut),
                            ),
                            child: const Center(
                              child: Text(
                                '🌸',
                                style: GoogleFonts.nunito(fontSize: 45),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // App Name
                      SlideTransition(
                        position: Tween<Offset>(
                                begin: const Offset(0, 0.5), end: Offset.zero)
                            .animate(
                          CurvedAnimation(
                              parent: _slideController,
                              curve: const Cubic(0.2, 0.8, 0.4, 1.0)),
                        ),
                        child: FadeTransition(
                          opacity: _slideController,
                          child: Column(
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.nunito(
                                    fontSize: 29,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                    fontFamily: 'Nunito',
                                    letterSpacing: -0.5,
                                  ),
                                  children: [
                                    TextSpan(text: 'Me'),
                                    TextSpan(
                                      text: 'Trustual',
                                      style: GoogleFonts.nunito(
                                        color: AppColors.primaryRose,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text('your cycle, your story 💕',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Loading Bar
                      FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _slideController,
                          curve: const Interval(0.5, 1.0),
                        ),
                        child: Container(
                          width: 100,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRose.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: AnimatedBuilder(
                            animation: _barController,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _barController.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF0C0C8),
                                        AppColors.primaryRose,
                                        Color(0xFFC060A0)
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
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

class PetalModel {
  final double left = math.Random().nextDouble() * 100;
  final double size = 12 + math.Random().nextDouble() * 14;
  final Duration duration =
      Duration(milliseconds: 4000 + math.Random().nextInt(3000));
  final Duration delay = Duration(milliseconds: math.Random().nextInt(3000));
  final String emoji = ['🌸', '✿', '🌺', '✾'][math.Random().nextInt(4)];
}

class FloatingPetal extends StatefulWidget {
  final PetalModel petal;
  const FloatingPetal({super.key, required this.petal});

  @override
  State<FloatingPetal> createState() => _FloatingPetalState();
}

class _FloatingPetalState extends State<FloatingPetal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.petal.duration);
    Future.delayed(widget.petal.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final opacity = progress < 0.08
            ? progress * 8.75
            : (progress > 0.85 ? (1 - progress) * 2 : 0.7);
        return Positioned(
          left: MediaQuery.of(context).size.width * (widget.petal.left / 100),
          bottom: MediaQuery.of(context).size.height * (progress * 1.1) - 50,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: progress * math.pi * 2.2,
              child: Text(widget.petal.emoji,
                  style: GoogleFonts.nunito(fontSize: widget.petal.size)),
            ),
          ),
        );
      },
    );
  }
}

class RippleRing extends StatefulWidget {
  final double delay;
  const RippleRing({super.key, required this.delay});

  @override
  State<RippleRing> createState() => _RippleRingState();
}

class _RippleRingState extends State<RippleRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800));
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return Opacity(
          opacity: (1 - progress) * 0.9,
          child: Transform.scale(
            scale: 0.5 + progress * 1.0,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primaryRose.withOpacity(0.15), width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}
