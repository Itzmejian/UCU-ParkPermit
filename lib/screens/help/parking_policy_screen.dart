import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/app_routes.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';

class _Rule {
  const _Rule(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class ParkingPolicyScreen extends StatelessWidget {
  const ParkingPolicyScreen({super.key});

  List<_Rule> get _rules => const [
        _Rule(
          Icons.directions_car_outlined,
          'Vehicle limit',
          'Each account can register up to $kMaxVehicles vehicles. A pending application counts as one.',
        ),
        _Rule(
          Icons.confirmation_number_outlined,
          'Permit sticker',
          'After approval you get a permit number printed on a sticker. Put it on your vehicle where the guard can see it. The guard checks the sticker and its number at the gate.',
        ),
        _Rule(
          Icons.do_not_disturb_on_outlined,
          'Stickers are not transferable',
          'A sticker belongs to one vehicle and one person. Do not lend it or move it to another vehicle.',
        ),
        _Rule(
          Icons.event_available_outlined,
          'Validity and renewal',
          'The Security Office sets how long your permit is valid. The date is shown in Permit Details. Renew before it expires.',
        ),
        _Rule(
          Icons.local_parking,
          'Without a valid permit',
          'Use the temporary visitor parking bays until your permit is approved or renewed.',
        ),
        _Rule(
          Icons.edit_note_outlined,
          'Changes to your vehicle',
          'A new plate number must be verified again by the Security Office. Changes to the make or model, color and year are saved right away.',
        ),
        _Rule(
          Icons.gavel_outlined,
          'Declined applications',
          'You have 7 days to file an appeal and resubmit the documents that need correcting.',
        ),
        _Rule(
          Icons.autorenew_rounded,
          'Lost or damaged sticker',
          'Request a replacement in Permit Details. The Security Office reviews the request.',
        ),
        _Rule(
          Icons.lock_outline,
          'Your documents and data',
          'Your documents are used only for your parking permit and are handled under the Data Privacy Act (RA 10173).',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parking Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Campus parking rules',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'The main rules that apply when you use UCU ParkPermit.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (final r in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(r.icon, size: 22, color: AppColors.navy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              r.body,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.45,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.goldDark),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a summary of how the app works. The full UCU parking ordinance will be added here once the Campus Security Office provides it.',
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SecondaryButton(
              label: 'See Parking Zones',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.parkingZones),
            ),
          ],
        ),
      ),
    );
  }
}