import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool localOnly = true;
  bool cloudBackup = false;
  bool biometricLock = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.textDark, size: 20),
                    onPressed: () => context.go('/profile'),
                  ),
                  Text(
                    'privacy_title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTrustBox(),
              const SizedBox(height: 20),
              _buildPrivacyCard(
                'Your choices',
                [
                  _buildToggleRow(
                      '📱 Keep data on my phone',
                      'Never leaves your device',
                      localOnly,
                      (v) => setState(() => localOnly = v)),
                  _buildToggleRow(
                      '☁️ Encrypted cloud backup',
                      'Only you can access it',
                      cloudBackup,
                      (v) => setState(() => cloudBackup = v)),
                  _buildToggleRow('🔒 Biometric lock', 'Face ID or fingerprint',
                      biometricLock, (v) => setState(() => biometricLock = v)),
                ],
              ),
              const SizedBox(height: 20),
              _buildPrivacyCard(
                'Export or delete',
                [
                  _buildActionButton(
                      '📥 Download my data', AppColors.textMid, false, () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing your data export...')));
                      }),
                  const SizedBox(height: 12),
                  _buildActionButton(
                      '🗑️ Delete everything', Colors.redAccent, true, () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Everything'),
                            content: const Text('This will permanently delete all your data. This action cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: GoogleFonts.nunito(color: Colors.redAccent))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
                           context.go('/splash');
                        }
                      }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🔐', style: GoogleFonts.nunito(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            'privacy_promise'.tr(),
            style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'We never sell your health data or show you ads. Everything is encrypted and you can delete it all anytime.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.textMid,
                fontWeight: FontWeight.w600,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildBadge('🔐 Encrypted'),
              _buildBadge('🚫 No Ads'),
              _buildBadge('🏠 Local-first'),
              _buildBadge('⚖️ GDPR'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border)),
      child: Text(text,
          style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textMid)),
    );
  }

  Widget _buildPrivacyCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildToggleRow(
      String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                Text(sub,
                    style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.primaryRose),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, bool isOutline, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutline ? Colors.white : color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          side: isOutline ? BorderSide(color: color.withOpacity(0.3)) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label),
      ),
    );
  }
}
