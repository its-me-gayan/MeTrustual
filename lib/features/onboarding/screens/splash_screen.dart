import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _barController;
  late AnimationController _fadeController;
  
  final List<PetalModel> _petals = List.generate(12, (index) => PetalModel());
  final List<double> _ringDelays = [0.0, 0.5, 1.0, 1.5];

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Start bar animation after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _barController.forward();
    });

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        _fadeController.forward().then((_) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.08).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
        ),
        child: Scaffold(
          backgroundColor: AppColors.cardBg,
          body: Stack(
            children: [
              // Floating Petals
              ..._petals.map((petal) => FloatingPetal(petal: petal)),
              
              // Ripple Rings
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: _ringDelays.map((delay) => RippleRing(delay: delay)).toList(),
                ),
              ),

              // Center Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Orbiting elements and Logo
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const OrbitingRing(
                            duration: Duration(seconds: 12),
                            reverse: true,
                            children: [
                              OrbitDot(emoji: '🌿'),
                              OrbitDot(emoji: '✨'),
                              OrbitDot(emoji: '🌿'),
                              OrbitDot(emoji: '✨'),
                            ],
                          ),
                          const OrbitingRing(
                            duration: Duration(seconds: 8),
                            children: [
                              OrbitDot(emoji: '💕', size: 14),
                              OrbitDot(emoji: '💕', size: 14),
                              OrbitDot(emoji: '💕', size: 14),
                              OrbitDot(emoji: '💕', size: 14),
                            ],
                          ),
                          ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.06).animate(
                              CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
                            ),
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.cycleCircleGradient,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryRose.withOpacity(0.3),
                                    blurRadius: 36,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🌸',
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // App Name
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                          fontFamily: 'Nunito',
                        ),
                        children: [
                          TextSpan(text: 'Me'),
                          TextSpan(
                            text: 'Trustual',
                            style: TextStyle(
                              color: AppColors.primaryRose,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'your cycle, your story 💕',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Loading Bar
                    Container(
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
                                  colors: [Color(0xFFF0C0C8), AppColors.primaryRose, Color(0xFFC060A0)],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetalModel {
  final double left = math.Random().nextDouble() * 100;
  final double size = 12 + math.Random().nextDouble() * 12;
  final Duration duration = Duration(milliseconds: 3000 + math.Random().nextInt(2500));
  final Duration delay = Duration(milliseconds: math.Random().nextInt(2000));
  final String emoji = ['🌸', '✿', '🌺', '✾'][math.Random().nextInt(4)];
}

class FloatingPetal extends StatefulWidget {
  final PetalModel petal;
  const FloatingPetal({super.key, required this.petal});

  @override
  State<FloatingPetal> createState() => _FloatingPetalState();
}

class _FloatingPetalState extends State<FloatingPetal> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.petal.duration);
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
        final opacity = progress < 0.1 ? progress * 6 : (progress > 0.8 ? (1 - progress) * 2 : 0.6);
        return Positioned(
          left: MediaQuery.of(context).size.width * (widget.petal.left / 100),
          bottom: MediaQuery.of(context).size.height * (1.1 - progress * 1.3),
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: progress * math.pi * 2,
              child: Text(widget.petal.emoji, style: TextStyle(fontSize: widget.petal.size)),
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

class _RippleRingState extends State<RippleRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
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
          opacity: (1 - progress) * 0.8,
          child: Transform.scale(
            scale: 0.6 + progress * 0.7,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRose.withOpacity(0.18), width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrbitingRing extends StatefulWidget {
  final Duration duration;
  final bool reverse;
  final List<Widget> children;
  const OrbitingRing({
    super.key,
    required this.duration,
    this.reverse = false,
    required this.children,
  });

  @override
  State<OrbitingRing> createState() => _OrbitingRingState();
}

class _OrbitingRingState extends State<OrbitingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
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
        return Transform.rotate(
          angle: _controller.value * math.pi * 2 * (widget.reverse ? -1 : 1),
          child: Stack(
            children: List.generate(widget.children.length, (index) {
              final angle = (index * 2 * math.pi) / widget.children.length;
              return Align(
                alignment: Alignment(math.cos(angle), math.sin(angle)),
                child: widget.children[index],
              );
            }),
          ),
        );
      },
    );
  }
}

class OrbitDot extends StatelessWidget {
  final String emoji;
  final double size;
  const OrbitDot({super.key, required this.emoji, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}
