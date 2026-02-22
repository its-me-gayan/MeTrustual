import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/uuid_persistence_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/backup_service.dart';
import '../../../models/user_profile_model.dart';

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
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            labelStyle: TextStyle(color: AppColors.textMid),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryRose)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textMid))),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Save', style: TextStyle(color: AppColors.primaryRose, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != profile.displayName) {
      setState(() => _isLoading = true);
      try {
        final firestore = ref.read(firestoreProvider);
        await firestore.collection('users').doc(profile.uid).collection('profile').doc('current').update({
          'displayName': result,
        });
        if (mounted) NotificationService.showSuccess(context, 'Profile updated!');
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

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            const SizedBox(height: 10),
            ...languages.map((lang) => ListTile(
              leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(lang['name']!, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: context.locale.languageCode == lang['code'] ? const Icon(Icons.check_circle, color: AppColors.primaryRose) : null,
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await auth.signOut();
        if (mounted) context.go('/splash');
      } catch (e) {
        if (mounted) NotificationService.showError(context, 'Failed to sign out: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleDeleteData() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.read(firestoreProvider);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text('This will permanently erase all your data from the cloud and this device. This action cannot be undone and the app will restart from the beginning.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete Everything', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final uid = user?.uid;
        
        // 1. Delete Firestore data if user exists
        if (uid != null) {
          // Delete profile subcollection
          final profileDocs = await firestore.collection('users').doc(uid).collection('profile').get();
          for (var doc in profileDocs.docs) {
            await doc.reference.delete();
          }
          // Delete user document
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
          NotificationService.showSuccess(context, 'All data erased successfully');
          context.go('/splash');
        }
      } catch (e) {
        if (mounted) NotificationService.showError(context, 'Error deleting data: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.watch(firestoreProvider);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: user != null 
            ? firestore.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
          builder: (context, snapshot) {
            final isPremium = snapshot.hasData && snapshot.data!.exists && (snapshot.data!.data()?['isPremium'] ?? false);
            
            return StreamBuilder(
              stream: user != null 
                ? firestore.collection('users').doc(user.uid).collection('profile').doc('current').snapshots()
                : const Stream.empty(),
              builder: (context, profileSnapshot) {
                UserProfile? profile;
                if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                  profile = UserProfile.fromFirestore(profileSnapshot.data!);
                }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
                        onPressed: () => context.go('/home'),
                      ),
                      Text(
                        'Profile & Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_isLoading) ...[
                        const SizedBox(width: 10),
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRose)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildProfileHeader(profile?.displayName ?? 'Lovely User', user?.isAnonymous == true ? 'Anonymous Mode' : (user?.email ?? 'No Email')),
                  const SizedBox(height: 24),
                  if (!isPremium) ...[
                    _buildPremiumBanner(),
                    const SizedBox(height: 30),
                  ] else ...[
                    _buildPremiumStatusCard(),
                    const SizedBox(height: 30),
                  ],
                  _buildSectionTitle('ACCOUNT'),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.person_outline, 'Edit Profile', () => _editProfile(profile)),
                    _buildSettingsTile(Icons.language, 'Language', _changeLanguage),
                    _buildSettingsTile(Icons.notifications_none, 'Notifications', () {
                      NotificationService.showSuccess(context, 'Notification settings coming soon!');
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('PREFERENCES'),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.lock_outline, 'Privacy & Security', () => context.go('/privacy')),
                    _buildSettingsTile(Icons.cloud_upload_outlined, 'Cloud Sync', () {
                       NotificationService.showSuccess(context, 'Cloud sync is active');
                    }),
                    _buildSettingsTile(Icons.palette_outlined, 'Theme', () {
                       NotificationService.showSuccess(context, 'Light theme is currently the only option');
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('DANGER ZONE'),
                  _buildSettingsCard([
                    if (isPremium)
                      _buildSettingsTile(
                        Icons.logout, 
                        'Sign Out', 
                        _handleSignOut, 
                        color: Colors.redAccent
                      ),
                    _buildSettingsTile(
                      Icons.delete_forever_outlined, 
                      'Delete All Data', 
                      _handleDeleteData, 
                      color: Colors.redAccent
                    ),
                  ]),
                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      'MeTrustual v1.0.0\nMade with ❤️ for you',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
                );
              }
            );
          }
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: AppColors.primaryRose.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          Text(email, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryRose.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MeTrustual Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  'Unlock all features and sync across devices.',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/premium'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryRose,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryRose.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: AppColors.primaryRose, shape: BoxShape.circle),
            child: const Icon(Icons.star, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Premium Member', style: TextStyle(color: AppColors.textDark, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text(
                  'Enjoy your unlimited access!',
                  style: TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w600),
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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFC0A0A8), letterSpacing: 1.0),
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

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textMid, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color ?? AppColors.textDark),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.border, size: 20),
      onTap: onTap,
    );
  }
}
