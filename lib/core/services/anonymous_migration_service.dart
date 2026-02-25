import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds a full snapshot of an anonymous user's data before they sign in
/// to a permanent account. We capture this BEFORE the Firebase Auth state
/// changes so we never lose it.
class AnonymousSnapshot {
  final String anonymousUid;
  final Map<String, dynamic> mainDoc; // users/{uid}
  final Map<String, dynamic>? journeyDoc; // users/{uid}/journey (single doc)
  final Map<String, dynamic>? settingsDoc; // users/{uid}/settings (single doc)
  final String? localLogsJson; // SharedPreferences 'daily_logs'

  const AnonymousSnapshot({
    required this.anonymousUid,
    required this.mainDoc,
    this.journeyDoc,
    this.settingsDoc,
    this.localLogsJson,
  });

  bool get hasAnyData =>
      mainDoc.isNotEmpty ||
      journeyDoc != null ||
      settingsDoc != null ||
      (localLogsJson != null && localLogsJson != '{}');
}

/// Describes how the merge went so the UI can show an informative message.
class MigrationResult {
  final bool success;
  final bool journeyMigrated;
  final bool settingsMigrated;
  final int logsMigrated;
  final String? error;

  const MigrationResult({
    required this.success,
    this.journeyMigrated = false,
    this.settingsMigrated = false,
    this.logsMigrated = 0,
    this.error,
  });
}

class AnonymousMigrationService {
  static const _stashedSnapshotKey = 'anon_migration_snapshot';

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 1 — Capture  (call this BEFORE signing in to the permanent account)
  // ─────────────────────────────────────────────────────────────────────────

  /// Reads the current anonymous user's Firestore data + local logs and returns
  /// a snapshot.  Also stashes the snapshot in SharedPreferences so it survives
  /// if the app restarts in the middle of the flow.
  static Future<AnonymousSnapshot?> captureAnonymousData({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) async {
    final user = auth.currentUser;
    if (user == null || !user.isAnonymous) return null;

    final uid = user.uid;
    Map<String, dynamic> mainDoc = {};
    Map<String, dynamic>? journeyDoc;
    Map<String, dynamic>? settingsDoc;

    try {
      // Main document
      final mainSnap = await firestore.collection('users').doc(uid).get();
      if (mainSnap.exists) mainDoc = mainSnap.data() ?? {};

      // journey subcollection: fetch first doc (named 'current' by onboarding)
      final journeyQuery = await firestore
          .collection('users')
          .doc(uid)
          .collection('journey')
          .limit(1)
          .get();
      if (journeyQuery.docs.isNotEmpty) {
        journeyDoc = journeyQuery.docs.first.data();
      }

      // settings subcollection: fetch first doc
      final settingsQuery = await firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .limit(1)
          .get();
      if (settingsQuery.docs.isNotEmpty) {
        settingsDoc = settingsQuery.docs.first.data();
      }
    } catch (e) {
      // Firestore read failed — we still continue with whatever we got
    }

    // Local daily logs (stored in SharedPreferences by log_provider.dart)
    String? localLogsJson;
    try {
      final prefs = await SharedPreferences.getInstance();
      localLogsJson = prefs.getString('daily_logs');
    } catch (_) {}

    final snapshot = AnonymousSnapshot(
      anonymousUid: uid,
      mainDoc: mainDoc,
      journeyDoc: journeyDoc,
      settingsDoc: settingsDoc,
      localLogsJson: localLogsJson,
    );

    // Stash it so we can recover if needed
    await _stashSnapshot(snapshot);
    return snapshot;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 2 — Safety check  (call after signing in, before merging)
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true when the target (permanent) account already has real data,
  /// which means the user should be warned before we touch it.
  static Future<bool> targetAccountHasData({
    required String targetUid,
    required FirebaseFirestore firestore,
  }) async {
    try {
      final mainSnap = await firestore.collection('users').doc(targetUid).get();
      if (!mainSnap.exists) return false;

      final data = mainSnap.data()!;
      // Consider "has data" if the journey was completed OR if there is a
      // lastPeriod recorded — i.e. the account is genuinely active.
      if (data['hasCompletedJourney'] == true) return true;

      final journeySnap = await firestore
          .collection('users')
          .doc(targetUid)
          .collection('journey')
          .doc('data')
          .get();
      return journeySnap.exists;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 3 — Merge  (the actual migration)
  // ─────────────────────────────────────────────────────────────────────────

  /// Merges [snapshot] data into [targetUid]'s Firestore documents.
  ///
  /// Rules:
  ///   - Main doc fields are only written when the target field is missing.
  ///   - journey doc is only written when the target has NO journey doc.
  ///   - settings doc is only written when the target has NO settings doc.
  ///   - Daily logs are merged by key (date-id); existing entries are kept.
  ///
  /// This "anonymous data fills gaps but never overwrites" policy is the key
  /// guard against an adversary who logs into someone else's account and
  /// inadvertently (or intentionally) corrupts their data.
  static Future<MigrationResult> mergeIntoTarget({
    required AnonymousSnapshot snapshot,
    required String targetUid,
    required FirebaseFirestore firestore,
  }) async {
    bool journeyMigrated = false;
    bool settingsMigrated = false;
    int logsMigrated = 0;

    try {
      final batch = firestore.batch();

      // ── 1. Main document ──────────────────────────────────────────────
      // Fetch existing target doc so we know which fields are already set.
      final targetMainSnap =
          await firestore.collection('users').doc(targetUid).get();
      final existing = targetMainSnap.data() ?? {};

      final mainUpdates = <String, dynamic>{};
      for (final entry in snapshot.mainDoc.entries) {
        // Skip internal / auth fields and any field already present
        if (_isSkippedField(entry.key)) continue;
        if (!existing.containsKey(entry.key)) {
          mainUpdates[entry.key] = entry.value;
        }
      }
      // ── Premium upgrade ─────────────────────────────────────────────────
      // If the anonymous account had isPremium: true (the user just paid),
      // upgrade the target account — even if the target previously had
      // premium cancelled (isPremium: false). The user paid; honour it.
      // We only do this upgrade, never a downgrade — if target is already
      // premium we leave it alone.
      final anonIsPremium = snapshot.mainDoc['isPremium'] == true;
      final targetIsPremium = existing['isPremium'] == true;

      if (anonIsPremium && !targetIsPremium) {
        mainUpdates['isPremium'] = true;
        // Carry the premiumSince timestamp from the anonymous account if
        // available, otherwise stamp now.
        mainUpdates['premiumSince'] =
            snapshot.mainDoc['premiumSince'] ?? FieldValue.serverTimestamp();
        // Clear any previous cancellation timestamp so the UI is clean.
        mainUpdates['cancelledAt'] = null;
      }

      // Always mark that a migration happened
      mainUpdates['migratedFromAnonymous'] = true;
      mainUpdates['migrationAt'] = FieldValue.serverTimestamp();

      final targetMainRef = firestore.collection('users').doc(targetUid);
      batch.set(targetMainRef, mainUpdates, SetOptions(merge: true));

      // ── 2. Journey subcollection ──────────────────────────────────────
      if (snapshot.journeyDoc != null && snapshot.journeyDoc!.isNotEmpty) {
        // Use 'current' — the doc name used by onboarding_provider.dart
        final targetJourneyRef = firestore
            .collection('users')
            .doc(targetUid)
            .collection('journey')
            .doc('current');
        final targetJourneySnap = await targetJourneyRef.get();
        if (!targetJourneySnap.exists) {
          batch.set(targetJourneyRef, snapshot.journeyDoc!);
          journeyMigrated = true;
        }
        // If target already has journey data we deliberately leave it alone.
      }

      // ── 3. Settings subcollection ─────────────────────────────────────
      if (snapshot.settingsDoc != null && snapshot.settingsDoc!.isNotEmpty) {
        final targetSettingsRef = firestore
            .collection('users')
            .doc(targetUid)
            .collection('settings')
            .doc('current');
        final targetSettingsSnap = await targetSettingsRef.get();
        if (!targetSettingsSnap.exists) {
          batch.set(targetSettingsRef, snapshot.settingsDoc!);
          settingsMigrated = true;
        }
      }

      await batch.commit();

      // ── 4. Local daily logs (SharedPreferences, not Firestore) ────────
      // Merge anonymous logs into whatever is already on device.
      // Because the device that ran the anonymous session IS the same device
      // the user is now signing in on, the logs are already present — nothing
      // to copy. But we make the keys deterministic so nothing is duplicated.
      if (snapshot.localLogsJson != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final existingJson = prefs.getString('daily_logs');

          final anonLogs =
              Map<String, dynamic>.from(jsonDecode(snapshot.localLogsJson!));
          final existingLogs = existingJson != null
              ? Map<String, dynamic>.from(jsonDecode(existingJson))
              : <String, dynamic>{};

          // Add anonymous log entries only if key not already present
          int added = 0;
          for (final entry in anonLogs.entries) {
            if (!existingLogs.containsKey(entry.key)) {
              existingLogs[entry.key] = entry.value;
              added++;
            }
          }

          if (added > 0) {
            await prefs.setString('daily_logs', jsonEncode(existingLogs));
            logsMigrated = added;
          }
        } catch (_) {}
      }

      // ── 5. Clear stash ────────────────────────────────────────────────
      await _clearStash();

      return MigrationResult(
        success: true,
        journeyMigrated: journeyMigrated,
        settingsMigrated: settingsMigrated,
        logsMigrated: logsMigrated,
      );
    } catch (e) {
      return MigrationResult(success: false, error: e.toString());
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STEP 4 — Cleanup  (delete the anonymous Firebase Auth account)
  // ─────────────────────────────────────────────────────────────────────────

  /// Queues the anonymous account for server-side deletion by writing a
  /// record to the pending_deletions collection.
  ///
  /// A Cloud Function watches this collection and uses the Admin SDK to:
  ///   1. Delete users/{anonymousUid} and all its subcollections.
  ///   2. Delete the Firebase Auth anonymous user.
  ///
  /// We cannot do this from the client because after sign-in the current
  /// user is the permanent user — isOwner(anonymousUid) would fail, and
  /// auth.currentUser.delete() only works on the currently signed-in user.
  ///
  /// Only call this after [mergeIntoTarget] succeeds.
  static Future<void> queueAnonymousAccountDeletion({
    required String anonymousUid,
    required FirebaseFirestore firestore,
  }) async {
    try {
      // pending_deletions/{uid} can only be CREATED, not read/updated/deleted
      // from the client (enforced by Firestore rules). The Cloud Function
      // picks this up and does the actual deletion using the Admin SDK.
      await firestore.collection('pending_deletions').doc(anonymousUid).set({
        'requestedAt': FieldValue.serverTimestamp(),
        'reason': 'anonymous_migration',
      });
    } catch (e) {
      // Non-fatal — orphaned anonymous accounts are cleaned up by a
      // scheduled Cloud Function anyway.
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Stash helpers  (survive app restarts mid-flow)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _stashSnapshot(AnonymousSnapshot snapshot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'anonymousUid': snapshot.anonymousUid,
        'mainDoc': snapshot.mainDoc,
        if (snapshot.journeyDoc != null) 'journeyDoc': snapshot.journeyDoc,
        if (snapshot.settingsDoc != null) 'settingsDoc': snapshot.settingsDoc,
        if (snapshot.localLogsJson != null)
          'localLogsJson': snapshot.localLogsJson,
      };
      await prefs.setString(_stashedSnapshotKey, jsonEncode(map));
    } catch (_) {}
  }

  /// Returns a previously stashed snapshot if one exists (app restarted
  /// mid-migration). The caller should complete the migration then clear it.
  static Future<AnonymousSnapshot?> getStashedSnapshot() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_stashedSnapshotKey);
      if (json == null) return null;

      final map = Map<String, dynamic>.from(jsonDecode(json));
      return AnonymousSnapshot(
        anonymousUid: map['anonymousUid'] as String,
        mainDoc: Map<String, dynamic>.from(map['mainDoc'] ?? {}),
        journeyDoc: map['journeyDoc'] != null
            ? Map<String, dynamic>.from(map['journeyDoc'])
            : null,
        settingsDoc: map['settingsDoc'] != null
            ? Map<String, dynamic>.from(map['settingsDoc'])
            : null,
        localLogsJson: map['localLogsJson'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _clearStash() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stashedSnapshotKey);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Fields we should never copy from an anonymous account to a permanent one.
  static bool _isSkippedField(String key) {
    const skip = {
      // isPremium / premiumSince are handled explicitly below — NOT blanket-skipped.
      // We upgrade the target when the anonymous account has isPremium: true.
      'email', // target account has its own email
      'createdAt', // keep original account creation date
      'uuidBackupDate',
      'deviceBackupTime',
      'migratedFromAnonymous',
      'migrationAt',
      'lastBackup',
      'backupSize',
    };
    return skip.contains(key);
  }
}
