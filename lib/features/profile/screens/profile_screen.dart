import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/mode_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../models/user_profile_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────
//  DELETION OVERLAY WIDGET
// ─────────────────────────────────────────────────────────
class _DeletionOverlay extends StatefulWidget {
  final Color themeColor;

  const _DeletionOverlay({required this.themeColor});

  @override
  State<_DeletionOverlay> createState() => _DeletionOverlayState();
}

class _DeletionOverlayState extends State<_DeletionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.themeColor.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated circle with gradient
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.themeColor.withOpacity(0.3),
                          widget.themeColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(widget.themeColor),
                        strokeWidth: 3.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Deleting Everything...',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              // Subtitle
              Text(
                'Please wait while we securely erase all your data',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Animated dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      final delay = index * 0.15;
                      final animValue =
                          (_animController.value - delay) % 1.0;
                      final opacity = (animValue < 0.5)
                          ? animValue * 2
                          : (1 - animValue) * 2;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.themeColor
                                .withOpacity(opacity.clamp(0.3, 1.0)),
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
      ),
    );
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _editProfile(UserProfile? profile) async {
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.displayName);
    final currentMode = ref.read(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode, soft: true);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile',
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900, color: AppColors.textDark)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: 'Display Name',
            labelStyle: GoogleFonts.nunito(color: AppColors.textMid),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: themeColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.nunito(color: AppColors.textMid))),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: Text('Save',
                style: GoogleFonts.nunito(
                    color: themeColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != profile.displayName) {
      setState(() => _isLoading = true);
      try {
        final firestore = ref.read(firestoreProvider);
        await firestore
            .collection('users')
            .doc(profile.uid)
            .collection('profile')
            .doc('current')
            .update({
          'displayName': result,
        });
        if (mounted)
          NotificationService.showSuccess(context, 'Profile updated!');
      } catch (e) {
        if (mounted) NotificationService.showError(context, e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeLanguage() async {
    final List<Map<String, String>> languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ms', 'name': 'Melayu', 'flag': '🇲🇾'},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    final currentMode = ref.read(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode, soft: true);

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select Language',
                style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            ...languages.map((lang) => ListTile(
                  leading: Text(lang['flag']!,
                      style: GoogleFonts.nunito(fontSize: 24)),
                  title: Text(lang['name']!,
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
                  trailing: context.locale.languageCode == lang['code']
                      ? Icon(Icons.check_circle, color: themeColor)
                      : null,
                  onTap: () {
                    context.setLocale(Locale(lang['code']!));
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    final auth = ref.read(firebaseAuthProvider);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sign Out',
                  style: GoogleFonts.nunito(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await auth.signOut();
        if (mounted) context.go('/splash');
      } catch (e) {
        if (mounted)
          NotificationService.showError(context, 'Failed to sign out: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleCancelPremium() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.read(firestoreProvider);

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Premium Membership',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
        content: const Text(
            'Are you sure you want to cancel your premium membership? You will lose access to all premium features.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Keep Premium',
                  style: GoogleFonts.nunito(color: AppColors.textMid))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes, Cancel',
                style: GoogleFonts.nunito(
                    color: Colors.redAccent, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await firestore.collection('users').doc(user.uid).update({
          'isPremium': false,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          NotificationService.showSuccess(
              context, 'Premium membership cancelled.');
        }
      } catch (e) {
        if (mounted) NotificationService.showError(context, e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteData() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.read(firestoreProvider);
    final currentMode = ref.read(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode, soft: true);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Data'),
        content: const Text(
            'This will permanently erase all your data from the cloud and this device. This action cannot be undone and the app will restart from the beginning.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete Everything',
                  style: GoogleFonts.nunito(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      // Show soothing deletion overlay
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _DeletionOverlay(themeColor: themeColor),
        );
      }

      try {
        final uid = user?.uid;

        // 1. Delete Firestore data if user exists
        if (uid != null) {
          // Helper function to delete all documents in a subcollection
          Future<void> deleteCollection(String collectionPath) async {
            try {
              final docs = await firestore
                  .collection('users')
                  .doc(uid)
                  .collection(collectionPath)
                  .get();
              for (var doc in docs.docs) {
                await doc.reference.delete();
              }
            } catch (e) {
              print('Error deleting $collectionPath: $e');
              // Continue with other collections even if one fails
            }
          }

          // Delete all subcollections
          await deleteCollection('profile');
          await deleteCollection('settings');
          await deleteCollection('cycles');
          await deleteCollection('ritual_completions');
          await deleteCollection('journey');

          // Finally delete the main user document
          await firestore.collection('users').doc(uid).delete();
        }

        // 2. Clear Local Storage
        await UUIDPersistenceService.clearUUID();
        await BiometricService.resetBiometric();
        await BackupService.clearLocalBackup();

        // Reset journey status in provider
        await ref.read(modeProvider.notifier).resetJourney();

        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 3. Delete Firebase Auth User (if possible)
        if (user != null) {
          try {
            await user.delete();
          } catch (e) {
            // User might need to re-authenticate to delete,
            // but we've already cleared their data and local state.
            // Just sign out as fallback.
            await auth.signOut();
          }
        }

        if (mounted) {
          // Close the deletion overlay
          Navigator.pop(context);
          NotificationService.showSuccess(
              context, 'All data erased successfully');
          context.go('/splash');
        }
      } catch (e) {
        if (mounted) {
          // Close the deletion overlay
          Navigator.pop(context);
          NotificationService.showError(context, 'Error deleting data: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.watch(firestoreProvider);
    final currentMode = ref.watch(modeProvider);
    final themeColor = AppColors.getModeColor(currentMode, soft: true);

    return Scaffold(
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('profile')
                  .doc('current')
                  .snapshots(),
              builder: (context, snapshot) {
                final profile = snapshot.data != null
                    ? UserProfile.fromFirestore(snapshot.data!)
                    : null;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(user.displayName ?? 'User',
                          user.email ?? 'No email', themeColor),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (profile != null)
                              _buildProfileCard(profile, themeColor),
                            const SizedBox(height: 24),
                            _buildSectionTitle('ACCOUNT'),
                            _buildSettingsCard([
                              _buildSettingsTile(Icons.person, 'Edit Profile',
                                  () => _editProfile(profile)),
                              _buildSettingsTile(Icons.language, 'Language',
                                  _changeLanguage),
                              _buildSettingsTile(Icons.notifications, 'Notifications',
                                  () {}),
                            ]),
                            const SizedBox(height: 24),
                            _buildSectionTitle('PREFERENCES'),
                            _buildSettingsCard([
                              _buildSettingsTile(Icons.lock, 'Privacy & Security',
                                  () {}),
                              _buildSettingsTile(Icons.cloud, 'Cloud Sync',
                                  () {}),
                              _buildSettingsTile(Icons.palette, 'Theme',
                                  () {}),
                            ]),
                            const SizedBox(height: 24),
                            _buildSectionTitle('DANGER ZONE'),
                            _buildSettingsCard([
                              if (user.isAnonymous == false)
                                _buildSettingsTile(
                                    Icons.star_border,
                                    'Cancel Premium Membership',
                                    _handleCancelPremium,
                                    color: Colors.redAccent),
                              _buildSettingsTile(
                                  Icons.logout, 'Sign Out', _handleSignOut,
                                  color: Colors.redAccent),
                              _buildSettingsTile(Icons.delete_forever_outlined,
                                  'Delete All Data', _handleDeleteData,
                                  color: Colors.redAccent),
                            ]),
                            const SizedBox(height: 40),
                            Center(
                              child: Text(
                                'MeTrustual v1.0.0\nMade with ❤️ for you',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
    );
  }

  Widget _buildProfileHeader(String name, String email, Color themeColor) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [themeColor.withOpacity(0.7), themeColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.nunito(
                fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: GoogleFonts.nunito(
                fontSize: 13, color: AppColors.textMid, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor.withOpacity(0.15), themeColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildProfileInfoRow('Age Group', profile.ageGroup),
          _buildProfileInfoRow('Region', profile.region),
          _buildProfileInfoRow('Language', profile.language),
          _buildProfileInfoRow('Life Stage', profile.lifeStage),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMid),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [themeColor, themeColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: themeColor.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MeTrustual Premium',
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Unlock all features and sync across devices.',
                  style: GoogleFonts.nunito(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: themeColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text('Upgrade',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusCard(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFFFF9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: themeColor, shape: BoxShape.circle),
            child: const Icon(Icons.star, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Member',
                    style: GoogleFonts.nunito(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                  'Enjoy your unlimited access!',
                  style: GoogleFonts.nunito(
                      color: AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFFC0A0A8),
            letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textMid, size: 22),
      title: Text(
        title,
        style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color ?? AppColors.textDark),
      ),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.border, size: 20),
      onTap: onTap,
    );
  }
}
