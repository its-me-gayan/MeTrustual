// This is a simple test to verify the routing setup
// The biometric setup screen should appear after onboarding completion

import 'package:go_router/go_router.dart';

void testRoutes() {
  // Test path matching
  final biometricPath = '/biometric-setup/user123';

  // GoRouter matches dynamic segments like :uid
  print('Path to navigate: $biometricPath');
  print('Expected UID from path: user123');

  // The route should be:
  // GoRoute(
  //   path: '/biometric-setup/:uid',
  //   builder: (context, state) {
  //     final uid = state.pathParameters['uid'] ?? '';
  //     return BiometricSetupScreen(uid: uid);
  //   },
  // ),
}

/* 
  DEBUGGING STEPS:
  
  1. Check console logs for these markers:
     - "📝 Starting onboarding..."
     - "✅ Onboarding completed"
     - "🆔 Got UID: xxx"
     - "🔀 Navigating to: /biometric-setup/xxx"
     - "🔐 BiometricSetupScreen initialized with UID: xxx"
  
  2. If any of these don't appear, check:
     - Is the button being tapped?
     - Is the completeOnboarding() function completing?
     - Is the UID null?
     - Is context.push() throwing an error?
  
  3. Common issues:
     - UID might be null if async operation hasn't completed
     - Route path syntax might be wrong
     - Screen might not be imported in router
*/
