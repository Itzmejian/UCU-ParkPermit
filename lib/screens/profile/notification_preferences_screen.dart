import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/profile_store.dart';
import '../../widgets/settings_tile.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SettingsStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Preferences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, child) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text(
                  'Choose which alerts appear in your notification bell.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                SettingsGroup(
                  title: 'Alerts',
                  children: [
                    SettingsSwitchTile(
                      icon: Icons.description_outlined,
                      title: 'Permit updates',
                      subtitle: 'Submitted, under review, approved, declined and appeal results',
                      value: s.permitUpdates,
                      onChanged: s.setPermitUpdates,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Sticker pickup',
                      subtitle: 'When your permit sticker is ready or a replacement is requested',
                      value: s.stickerReminders,
                      onChanged: s.setStickerReminders,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.event_busy_outlined,
                      title: 'Expiry reminders',
                      subtitle: 'When your permit is about to expire or has expired',
                      value: s.expiryReminders,
                      onChanged: s.setExpiryReminders,
                    ),
                    SettingsSwitchTile(
                      icon: Icons.person_outline,
                      title: 'Account activity',
                      subtitle: 'Welcome messages and changes to your account',
                      value: s.accountActivity,
                      onChanged: s.setAccountActivity,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 20, color: AppColors.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Alerts are shown inside the app only. We do not send text messages. Turning an alert off means you will not get that kind of notification, so check your Home screen for the latest status.',
                          style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}