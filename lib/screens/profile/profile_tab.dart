import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/date_format.dart';
import '../../models/profile_store.dart';
import '../../widgets/settings_tile.dart';
import '../../widgets/status_badge.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
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
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  Widget _profileCard(ProfileStore p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
            ),
            child: Text(
              p.initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.idNumber.isEmpty ? p.email : 'ID: ${p.idNumber}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusBadge(text: p.roleLabel.toUpperCase(), tone: BadgeTone.gold),
                    const StatusBadge(text: 'EMAIL VERIFIED', tone: BadgeTone.green),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ProfileStore.instance;
    final settings = SettingsStore.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([profile, settings]),
      builder: (context, child) {
        final changed = settings.passwordUpdatedAt;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _profileCard(profile),
            const SizedBox(height: 20),
            SettingsGroup(
              title: 'Account & preferences',
              children: [
                SettingsTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Personal info, contact number, address',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                ),
                SettingsTile(
                  icon: Icons.key_outlined,
                  title: 'Change Password',
                  subtitle: changed == null
                      ? 'Not changed since registration'
                      : 'Last changed ${formatLongDate(changed)}',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
                ),
                SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Preferences',
                  subtitle: 'Choose which alerts you get',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.notificationPreferences),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Security & legal',
              children: [
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy & Security',
                  subtitle: 'Your data, sessions and RA 10173',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacySecurity),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Help & information',
              children: [
                SettingsTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Answers to common questions',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.help),
                ),
                SettingsTile(
                  icon: Icons.menu_book_outlined,
                  title: 'Permit Requirements',
                  subtitle: 'What you need to apply',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.permitRequirements),
                ),
                SettingsTile(
                  icon: Icons.policy_outlined,
                  title: 'Parking Policy',
                  subtitle: 'Campus parking rules',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.parkingPolicy),
                ),
                SettingsTile(
                  icon: Icons.map_outlined,
                  title: 'Parking Zones',
                  subtitle: 'Where you can park',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.parkingZones),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SettingsGroup(
              title: 'Session',
              children: [
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  subtitle: 'Sign out of this device',
                  danger: true,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Column(
              children: [
                Text(
                  'UCU ParkPermit v1.0',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'UCU Safety & Campus Security Enforcement Office',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}