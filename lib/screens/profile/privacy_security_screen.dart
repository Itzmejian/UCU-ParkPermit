import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/status_badge.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  Widget _caption(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.goldDark,
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This option will be available when the app is connected to the server.'),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to see your permit.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy & Security',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _caption('HOW YOUR DATA IS USED'),
                  const SizedBox(height: 8),
                  _bullet(
                    Icons.person_outline,
                    'We collect your profile, vehicle details and the documents you upload (driver\'s license, OR/CR and UCU ID).',
                  ),
                  _bullet(
                    Icons.local_parking,
                    'They are used only to review your parking permit application and to issue your permit.',
                  ),
                  _bullet(
                    Icons.lock_outline,
                    'Your documents are kept in private storage. Only the Campus Security Office can open them for review.',
                  ),
                  _bullet(
                    Icons.visibility_off_outlined,
                    'Other users cannot see your information.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _caption('DATA PRIVACY ACT (RA 10173)')),
                      const StatusBadge(text: 'YOUR RIGHTS', tone: BadgeTone.gray),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Under the Data Privacy Act of 2012, you have the right to be informed about how your data is used, to see the data we hold about you, to correct it, and to withdraw your consent.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Your data',
              children: [
                SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Download my data',
                  subtitle: 'Get a copy of your information',
                  onTap: () => _soon(context),
                ),
                SettingsTile(
                  icon: Icons.delete_outline,
                  title: 'Request account deletion',
                  subtitle: 'Ask to remove your account and data',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _caption('ACTIVE SESSION'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.smartphone, size: 20, color: AppColors.navy),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This device',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Signed in now',
                              style: TextStyle(fontSize: 12.5, color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(text: 'ACTIVE', tone: BadgeTone.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              label: 'Change Password',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.changePassword),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
              label: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}