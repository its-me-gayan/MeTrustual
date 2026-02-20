import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/firebase_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                ],
              ),
              const SizedBox(height: 30),
              _buildProfileHeader(user?.displayName ?? 'Lovely User', user?.email ?? 'Anonymous Mode'),
              const SizedBox(height: 30),
              _buildSectionTitle('ACCOUNT'),
              _buildSettingsCard([
                _buildSettingsTile(Icons.person_outline, 'Edit Profile', () {}),
                _buildSettingsTile(Icons.language, 'Language', () {}),
                _buildSettingsTile(Icons.notifications_none, 'Notifications', () {}),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('PREFERENCES'),
              _buildSettingsCard([
                _buildSettingsTile(Icons.lock_outline, 'Privacy & Security', () => context.go('/privacy')),
                _buildSettingsTile(Icons.cloud_upload_outlined, 'Cloud Sync', () {}),
                _buildSettingsTile(Icons.palette_outlined, 'Theme', () {}),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('DANGER ZONE'),
              _buildSettingsCard([
                _buildSettingsTile(Icons.logout, 'Sign Out', () async {
                  await auth.signOut();
                  if (context.mounted) context.go('/');
                }, color: Colors.redAccent),
                _buildSettingsTile(Icons.delete_forever_outlined, 'Delete Account', () {}, color: Colors.redAccent),
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
