// import 'dart:async';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../core/theme/app_colors.dart';
// import '../../../core/providers/mode_provider.dart';
// import '../../../core/services/biometric_service.dart';
// import '../../../core/providers/firebase_providers.dart';
// import '../../../core/providers/security_provider.dart';
// import '../../../core/services/notification_service.dart';

// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen>
//     with TickerProviderStateMixin {
//   late AnimationController _logoController;
//   late AnimationController _barController;
//   late AnimationController _fadeController;
//   late AnimationController _slideController;

//   final List<PetalModel> _petals = List.generate(15, (index) => PetalModel());
//   final List<double> _ringDelays = [0.0, 0.7, 1.4];

//   @override
//   void initState() {
//     super.initState();

//     _logoController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2500),
//     )..repeat(reverse: true);

//     _barController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 2200),
//     );

//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );

//     _slideController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );

//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (mounted) {
//         _slideController.forward();
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted) _barController.forward();
//         });
//       }
//     });

//     Future.delayed(const Duration(milliseconds: 3200), () {
//       if (mounted) {
//         _fadeController.forward().then((_) async {
//           await _handleNavigation();
//         });
//       }
//     });
//   }

//   Future<void> _handleNavigation() async {
//     try {
//       final auth = ref.read(firebaseAuthProvider);
//       final uid = auth.currentUser?.uid;

//       // User is not logged in
//       if (uid == null) {
//         if (mounted) context.go('/onboarding');
//         return;
//       }

//       // Check if user is anonymous
//       if (auth.currentUser!.isAnonymous) {
//         // Anonymous user - check if PIN is set up
//         final biometricSetUp = await BiometricService.isBiometricSetUp();
//         if (!biometricSetUp) {
//           // New anonymous user - route to biometric setup
//           if (mounted) context.go('/biometric-setup/$uid');
//           return;
//         }

//         // Anonymous user with PIN set up - verify PIN
//         if (mounted) {
//           final verified = await _verifyPinInteractively();
//           if (!verified) {
//             if (mounted) context.go('/onboarding');
//             return;
//           }
//         }
//       } else {
//         // Authenticated user (email/password login)
//         // Check if they have a PIN set up locally
//         final biometricSetUp = await BiometricService.isBiometricSetUp();

//         if (!biometricSetUp) {
//           // New device for authenticated user - prompt to set up PIN
//           if (mounted) {
//             final shouldSetPin = await showDialog<bool>(
//               context: context,
//               barrierDismissible: false,
//               builder: (context) => AlertDialog(
//                 title: const Text('Set Up PIN'),
//                 content: const Text(
//                   'Welcome back! Set up a PIN for this device to secure your account.',
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, false),
//                     child: const Text('Skip'),
//                   ),
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, true),
//                     child: const Text('Set PIN Now'),
//                   ),
//                 ],
//               ),
//             );

//             if (shouldSetPin == true) {
//               if (mounted) context.go('/biometric-setup/$uid');
//               return;
//             }
//           }
//         } else {
//           // Authenticated user with PIN on this device - verify PIN
//           if (mounted) {
//             final verified = await _verifyPinInteractively();
//             if (!verified) {
//               if (mounted) context.go('/onboarding');
//               return;
//             }
//           }
//         }
//       }

//       // Sync with Firestore before deciding navigation
//       await ref.read(modeProvider.notifier).syncFromFirestore();

//       final hasCompleted =
//           ref.read(modeProvider.notifier).hasCompletedJourney;
//       if (mounted) {
//         context.go(hasCompleted ? '/home' : '/onboarding');
//       }
//     } catch (e) {
//       print('❌ Navigation error: $e');
//       if (mounted) context.go('/onboarding');
//     }
//   }

//   /// Verify PIN interactively with retry logic
//   Future<bool> _verifyPinInteractively() async {
//     try {
//       final security = ref.read(securityProvider.notifier);

//       // Show PIN verification dialog up to 3 times
//       for (int attempt = 0; attempt < 3; attempt++) {
//         final pin = await showDialog<String?>(
//           context: context,
//           barrierDismissible: false,
//           builder: (ctx) => _buildPINDialog(attempt + 1),
//         );

//         if (pin == null) {
//           print('❌ PIN entry cancelled by user');
//           return false;
//         }

//         final verified = await security.verifyPinWithCloudFallback(pin);
//         if (verified) {
//           print('✅ PIN verified!');
//           return true;
//         }

//         print('❌ Wrong PIN. Attempt ${attempt + 1}/3');
//         if (mounted && attempt < 2) {
//           // Don't show notifications on splash screen - they'll be shown in the PIN dialog instead
//           print('Attempts remaining: ${3 - attempt - 1}');
//         }
//       }

//       print('❌ Max PIN attempts exceeded');
//       return false;
//     } catch (e) {
//       print('❌ Verification error: $e');
//       return false;
//     }
//   }

//   /// Build PIN entry dialog with improved UI
//   Widget _buildPINDialog(int attempt) {
//     final controller = TextEditingController();
//     return AlertDialog(
//       title: const Text('🔐 Enter PIN to unlock'),
//       content: TextField(
//         controller: controller,
//         obscureText: true,
//         keyboardType: TextInputType.number,
//         maxLength: 4,
//         decoration: InputDecoration(
//           hintText: '4-digit PIN',
//           counterText: '',
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: AppColors.border),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: AppColors.border),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: AppColors.primaryRose, width: 2),
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context, null),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: () => Navigator.pop(context, controller.text.trim()),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: AppColors.primaryRose,
//           ),
//           child: const Text('Unlock', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     );
//   }

//   @override
//   void dispose() {
//     _logoController.dispose();
//     _barController.dispose();
//     _fadeController.dispose();
//     _slideController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_fadeController),
//       child: ScaleTransition(
//         scale: Tween<double>(begin: 1.0, end: 1.06).animate(
//           CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
//         ),
//         child: Scaffold(
//           body: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   Color(0xFFFFF0F0),
//                   Color(0xFFFDE8F0),
//                   Color(0xFFF0E8FC),
//                 ],
//                 stops: [0.0, 0.4, 1.0],
//               ),
//             ),
//             child: Stack(
//               children: [
//                 ..._petals.map((petal) => FloatingPetal(petal: petal)),
//                 Center(
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: _ringDelays
//                         .map((delay) => RippleRing(delay: delay))
//                         .toList(),
//                   ),
//                 ),
//                 Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ScaleTransition(
//                         scale: Tween<double>(begin: 1.0, end: 1.07).animate(
//                           CurvedAnimation(
//                               parent: _logoController, curve: Curves.easeInOut),
//                         ),
//                         child: Container(
//                           width: 100,
//                           height: 100,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: AppColors.cycleCircleGradient,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFFFCE8E8).withOpacity(0.5),
//                                 blurRadius: 0,
//                                 spreadRadius: 10,
//                               ),
//                               BoxShadow(
//                                 color: AppColors.primaryRose.withOpacity(0.3),
//                                 blurRadius: 36,
//                                 offset: const Offset(0, 12),
//                               ),
//                             ],
//                           ),
//                           child: RotationTransition(
//                             turns: Tween<double>(begin: -0.014, end: 0.014)
//                                 .animate(
//                               CurvedAnimation(
//                                   parent: _logoController,
//                                   curve: Curves.easeInOut),
//                             ),
//                             child: const Center(
//                               child: Text(
//                                 '🌸',
//                                 style: TextStyle(fontSize: 45),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 14),
//                       SlideTransition(
//                         position: Tween<Offset>(
//                                 begin: const Offset(0, 0.5), end: Offset.zero)
//                             .animate(
//                           CurvedAnimation(
//                               parent: _slideController,
//                               curve: const Cubic(0.2, 0.8, 0.4, 1.0)),
//                         ),
//                         child: FadeTransition(
//                           opacity: _slideController,
//                           child: Column(
//                             children: [
//                               RichText(
//                                 text: const TextSpan(
//                                   style: TextStyle(
//                                     fontSize: 29,
//                                     fontWeight: FontWeight.w900,
//                                     color: AppColors.textDark,
//                                     fontFamily: 'Nunito',
//                                     letterSpacing: -0.5,
//                                   ),
//                                   children: [
//                                     TextSpan(text: 'Me'),
//                                     TextSpan(
//                                       text: 'Trustual',
//                                       style: TextStyle(
//                                         color: AppColors.primaryRose,
//                                         fontStyle: FontStyle.italic,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 'Your health, your choice',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w700,
//                                   color: AppColors.textMuted,
//                                   letterSpacing: 0.5,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Animation models and widgets (same as before)
// class PetalModel {
//   late double x, y, vx, vy, size, rotation;
//   late Duration delay;

//   PetalModel() {
//     x = math.Random().nextDouble() * 400 - 200;
//     y = math.Random().nextDouble() * 800 - 400;
//     vx = (math.Random().nextDouble() - 0.5) * 2;
//     vy = math.Random().nextDouble() * 2 + 0.5;
//     size = math.Random().nextDouble() * 20 + 10;
//     rotation = math.Random().nextDouble() * 360;
//     delay = Duration(milliseconds: math.Random().nextInt(2000));
//   }
// }

// class FloatingPetal extends StatefulWidget {
//   final PetalModel petal;

//   const FloatingPetal({super.key, required this.petal});

//   @override
//   State<FloatingPetal> createState() => _FloatingPetalState();
// }

// class _FloatingPetalState extends State<FloatingPetal>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 8),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         final progress = _controller.value;
//         return Positioned(
//           left: 200 + widget.petal.x + (progress * widget.petal.vx * 100),
//           top: 400 + widget.petal.y + (progress * widget.petal.vy * 100),
//           child: Opacity(
//             opacity: (1 - progress).clamp(0, 1).toDouble(),
//             child: Transform.rotate(
//               angle: widget.petal.rotation * 0.01745,
//               child: Text(
//                 '🌸',
//                 style: TextStyle(fontSize: widget.petal.size),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class RippleRing extends StatefulWidget {
//   final double delay;

//   const RippleRing({super.key, required this.delay});

//   @override
//   State<RippleRing> createState() => _RippleRingState();
// }

// class _RippleRingState extends State<RippleRing>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         final progress = (_controller.value + widget.delay / 2) % 1.0;
//         return Container(
//           width: 100 + (progress * 150),
//           height: 100 + (progress * 150),
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: AppColors.primaryRose.withOpacity(0.3 * (1 - progress)),
//               width: 2,
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
