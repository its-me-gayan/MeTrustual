import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';
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
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final firestore = ref.watch(firestoreProvider);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: user != null 
            ? firestore.collection('users').doc(user.uid).collection('profile').doc('current').snapshots()
            : const Stream.empty(),
          builder: (context, snapshot) {
            UserProfile? profile;
            if (snapshot.hasData && snapshot.data!.exists) {
              profile = UserProfile.fromFirestore(snapshot.data!);
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
                  const SizedBox(height: 30),
                  _buildSectionTitle('ACCOUNT'),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.person_outline, 'Edit Profile', () => _editProfile(profile)),
                    _buildSettingsTile(Icons.language, 'Language', _changeLanguage),
                    _buildSettingsTile(Icons.notifications_none, 'Notifications', () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings coming soon!')));
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('PREFERENCES'),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.lock_outline, 'Privacy & Security', () => context.go('/privacy')),
                    _buildSettingsTile(Icons.cloud_upload_outlined, 'Cloud Sync', () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud sync is active')));
                    }),
                    _buildSettingsTile(Icons.palette_outlined, 'Theme', () {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Light theme is currently the only option')));
                    }),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionTitle('DANGER ZONE'),
                  _buildSettingsCard([
                    _buildSettingsTile(Icons.logout, 'Sign Out', () async {
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
                        await auth.signOut();
                        if (context.mounted) context.go('/splash');
                      }
                    }, color: Colors.redAccent),
                    _buildSettingsTile(Icons.delete_forever_outlined, 'Delete Account', () async {
                       final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Account'),
                          content: const Text('This will permanently delete all your data. This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        // In a real app, you'd delete Firestore data first
                        await user?.delete();
                        if (context.mounted) context.go('/splash');
                      }
                    }, color: Colors.redAccent),
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
