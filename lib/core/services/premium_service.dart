import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Replace these with your actual RevenueCat API keys
//  from https://app.revenuecat.com → Project → API Keys
// ─────────────────────────────────────────────────────────────────────────────
const _kRevenueCatAppleKey = 'test_TKxWcBNOjDHAKzFzoBifpbAmCDm'; // iOS
const _kRevenueCatGoogleKey = 'test_TKxWcBNOjDHAKzFzoBifpbAmCDm'; // Android

// The entitlement identifier you set in RevenueCat dashboard
const _kPremiumEntitlement = 'Soluna Pro';

// ─────────────────────────────────────────────────────────────────────────────
//  Richer status — not just a bool
// ─────────────────────────────────────────────────────────────────────────────
class PremiumStatus {
  /// User has an active entitlement right now
  final bool isActive;

  /// Subscription exists but user cancelled — still active until [expiresAt]
  final bool isCancelledButActive;

  /// Apple/Google couldn't charge the card — grace period is ticking
  final bool isInBillingGracePeriod;

  /// When the current period ends (null for lifetime)
  final DateTime? expiresAt;

  /// Lifetime purchase — never expires
  final bool isLifetime;

  const PremiumStatus({
    required this.isActive,
    this.isCancelledButActive = false,
    this.isInBillingGracePeriod = false,
    this.expiresAt,
    this.isLifetime = false,
  });

  /// "Your premium ends on March 17" — shown in profile when cancelled
  String? get expiryWarning {
    if (!isCancelledButActive || expiresAt == null) return null;
    final days = expiresAt!.difference(DateTime.now()).inDays;
    if (days <= 0) return 'Your premium has expired.';
    if (days == 1) return 'Your premium ends tomorrow.';
    if (days <= 7) return 'Your premium ends in $days days.';
    return 'Your premium ends on ${_formatDate(expiresAt!)}';
  }

  String? get billingWarning {
    if (!isInBillingGracePeriod) return null;
    return 'Payment issue detected — please update your billing info to keep premium.';
  }

  static String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
//  PremiumService
// ─────────────────────────────────────────────────────────────────────────────
class PremiumService {
  // ── Init — call once from main() before runApp() ──────────────────────────
  static const bool _useMock = kDebugMode; // Enable mock in debug mode

  static Future<void> init({String? uid}) async {
    if (_useMock) {
      debugPrint('🚀 PremiumService: Running in MOCK mode');
      return;
    }
    try {
      await Purchases.setLogLevel(
        kDebugMode ? LogLevel.debug : LogLevel.error,
      );

      final config = PurchasesConfiguration(
        defaultTargetPlatform == TargetPlatform.iOS
            ? _kRevenueCatAppleKey
            : _kRevenueCatGoogleKey,
      );

      await Purchases.configure(config);

      if (uid != null && uid.isNotEmpty) {
        await Purchases.logIn(uid);
      }
    } catch (e) {
      debugPrint('⚠️  PremiumService.init error: $e');
    }
  }

  // ── Start listening for real-time entitlement changes ─────────────────────
  //
  // RevenueCat fires this callback whenever the store reports a change:
  //   • Subscription renews successfully
  //   • Subscription expires after cancellation
  //   • Refund is processed
  //   • Billing grace period starts/ends
  //
  // Because premiumStatusProvider already streams from Firestore, writing
  // here is enough — every PremiumGate in the app instantly reacts.
  static void startListening({
    required String uid,
    required FirebaseFirestore firestore,
  }) {
    if (_useMock) return;
    Purchases.addCustomerInfoUpdateListener((customerInfo) async {
      debugPrint('🔔 RevenueCat CustomerInfo updated — syncing to Firestore');
      final status = _statusFromCustomerInfo(customerInfo);
      await _writeStatusToFirestore(
          uid: uid, firestore: firestore, status: status);
    });
  }

  // ── Stop listening (call when user signs out) ─────────────────────────────
  static void stopListening() {
    Purchases.removeCustomerInfoUpdateListener((_) {});
  }

  // ── Verify on splash / app resume ────────────────────────────────────────
  //
  // Asks the store for current entitlement status and syncs to Firestore.
  // Falls back to existing Firestore value on network error (don't punish
  // offline users by revoking access they legitimately paid for).
  static Future<PremiumStatus> verifyAndSync({
    required String uid,
    required FirebaseFirestore firestore,
  }) async {
    if (_useMock) {
      final doc = await firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      return PremiumStatus(
        isActive: data['isPremium'] == true,
        isCancelledButActive: data['premiumCancelled'] == true,
        isInBillingGracePeriod: data['premiumBillingIssue'] == true,
        expiresAt: data['premiumExpiresAt'] != null
            ? DateTime.tryParse(data['premiumExpiresAt'] as String)
            : null,
        isLifetime: data['premiumIsLifetime'] == true,
      );
    }
    try {
      // Make sure RevenueCat knows which user this is
      final currentInfo = await Purchases.getCustomerInfo();
      if (currentInfo.originalAppUserId != uid) {
        await Purchases.logIn(uid);
      }

      final customerInfo = await Purchases.getCustomerInfo();
      final status = _statusFromCustomerInfo(customerInfo);
      await _writeStatusToFirestore(
          uid: uid, firestore: firestore, status: status);

      debugPrint('✅ PremiumService verified: active=${status.isActive} '
          'cancelled=${status.isCancelledButActive} '
          'billing=${status.isInBillingGracePeriod}');

      return status;
    } catch (e) {
      debugPrint(
          '⚠️  PremiumService.verifyAndSync error: $e — using cached value');
      // Network / store unavailable: read from Firestore rather than revoking
      try {
        final doc = await firestore.collection('users').doc(uid).get();
        final data = doc.data() ?? {};
        return PremiumStatus(
          isActive: data['isPremium'] == true,
          isCancelledButActive: data['premiumCancelled'] == true,
          isInBillingGracePeriod: data['premiumBillingIssue'] == true,
          expiresAt: data['premiumExpiresAt'] != null
              ? DateTime.tryParse(data['premiumExpiresAt'] as String)
              : null,
          isLifetime: data['premiumIsLifetime'] == true,
        );
      } catch (_) {
        return const PremiumStatus(isActive: false);
      }
    }
  }

  // ── Make a purchase ───────────────────────────────────────────────────────
  static Future<PurchaseResult> purchase({
    required Package packageToBuy,
    required String uid,
    required FirebaseFirestore firestore,
  }) async {
    if (_useMock) {
      final status = PremiumStatus(
        isActive: true,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      await _writeStatusToFirestore(
          uid: uid, firestore: firestore, status: status);
      await firestore.collection('users').doc(uid).set({
        'premiumSince': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return PurchaseResult(success: true, status: status);
    }
    try {
      final customerInfo = await Purchases.purchasePackage(packageToBuy);
      final status = _statusFromCustomerInfo(customerInfo);

      if (status.isActive) {
        await _writeStatusToFirestore(
            uid: uid, firestore: firestore, status: status);
        // Also stamp premiumSince on first purchase
        await firestore.collection('users').doc(uid).set({
          'premiumSince': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return PurchaseResult(success: status.isActive, status: status);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(success: false, cancelled: true);
      }
      return PurchaseResult(success: false, errorMessage: e.toString());
    } catch (e) {
      return PurchaseResult(success: false, errorMessage: e.toString());
    }
  }

  // ── Restore purchases ─────────────────────────────────────────────────────
  //
  // Called when user taps "Restore Purchase" — hits the store receipt
  // directly, not RevenueCat cache. Syncs result to Firestore.
  static Future<RestoreResult> restore({
    required String uid,
    required FirebaseFirestore firestore,
  }) async {
    if (_useMock) {
      final status = PremiumStatus(
        isActive: true,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      await _writeStatusToFirestore(
          uid: uid, firestore: firestore, status: status);
      return RestoreResult(found: true, status: status);
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      final status = _statusFromCustomerInfo(customerInfo);
      await _writeStatusToFirestore(
          uid: uid, firestore: firestore, status: status);

      return RestoreResult(
        found: status.isActive || status.isCancelledButActive,
        status: status,
      );
    } catch (e) {
      debugPrint('⚠️  PremiumService.restore error: $e');
      return RestoreResult(found: false, errorMessage: e.toString());
    }
  }

  // ── Fetch offerings for the paywall ──────────────────────────────────────
  static Future<Offerings?> getOfferings() async {
    if (_useMock) return null; // In real app, you'd need to mock Offerings object if needed for UI
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('⚠️  PremiumService.getOfferings error: $e');
      return null;
    }
  }

  // ── Sign out of RevenueCat (call on Firebase sign-out) ───────────────────
  static Future<void> signOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('⚠️  PremiumService.signOut error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Private helpers
  // ─────────────────────────────────────────────────────────────────────────

  static PremiumStatus _statusFromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[_kPremiumEntitlement];
    final isActive = info.entitlements.active.containsKey(_kPremiumEntitlement);

    if (entitlement == null) {
      return const PremiumStatus(isActive: false);
    }

    final expiresAt = entitlement.expirationDate != null
        ? DateTime.tryParse(entitlement.expirationDate!)
        : null;

    // Lifetime: no expiry date and active
    final isLifetime = isActive && expiresAt == null;

    // Cancelled but still in paid period:
    // entitlement is active but willRenew is false
    final isCancelledButActive =
        isActive && !entitlement.willRenew && !isLifetime;

    // Billing issue: Apple/Google billing grace period
    final isInBillingGracePeriod =
        info.entitlements.active.containsKey(_kPremiumEntitlement) &&
            entitlement.billingIssueDetectedAt != null;

    return PremiumStatus(
      isActive: isActive,
      isCancelledButActive: isCancelledButActive,
      isInBillingGracePeriod: isInBillingGracePeriod,
      expiresAt: expiresAt,
      isLifetime: isLifetime,
    );
  }

  static Future<void> _writeStatusToFirestore({
    required String uid,
    required FirebaseFirestore firestore,
    required PremiumStatus status,
  }) async {
    await firestore.collection('users').doc(uid).set({
      'isPremium': status.isActive,
      'premiumVerifiedAt': FieldValue.serverTimestamp(),
      'premiumCancelled': status.isCancelledButActive,
      'premiumBillingIssue': status.isInBillingGracePeriod,
      'premiumExpiresAt': status.expiresAt?.toIso8601String(),
      'premiumIsLifetime': status.isLifetime,
    }, SetOptions(merge: true));
  }
}

// ── Result wrappers ───────────────────────────────────────────────────────────
class PurchaseResult {
  final bool success;
  final bool cancelled;
  final String? errorMessage;
  final PremiumStatus? status;

  const PurchaseResult({
    required this.success,
    this.cancelled = false,
    this.errorMessage,
    this.status,
  });
}

class RestoreResult {
  final bool found;
  final String? errorMessage;
  final PremiumStatus? status;

  const RestoreResult({
    required this.found,
    this.errorMessage,
    this.status,
  });
}
