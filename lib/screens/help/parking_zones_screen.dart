import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class _Zone {
  const _Zone(this.mark, this.title, this.vehicles, this.body, this.tone);

  final String mark;
  final String title;
  final String vehicles;
  final String body;
  final BadgeTone tone;
}

class ParkingZonesScreen extends StatelessWidget {
  const ParkingZonesScreen({super.key});

  static const List<_Zone> _zones = [
    _Zone(
      'A-C',
      'Zones A, B and C',
      '4-WHEEL VEHICLES',
      'Parking lots for sedans, hatchbacks, SUVs, MPVs and pickups.',
      BadgeTone.green,
    ),
    _Zone(
      'M',
      'Zone M',
      'MOTORCYCLES',
      'Parking bays for scooters, mopeds, underbones and big bikes.',
      BadgeTone.gold,
    ),
    _Zone(
      'V',
      'Visitor parking bays',
      'NO PERMIT YET',
      'Temporary bays for vehicles without an approved permit, such as while your application is pending or after your permit expired.',
      BadgeTone.gray,
    ),
  ];

  Color _tint(BadgeTone t) => switch (t) {
        BadgeTone.green => AppColors.successLight,
        BadgeTone.gold => AppColors.goldLight,
        BadgeTone.red => AppColors.errorLight,
        BadgeTone.gray => AppColors.inputFill,
      };

  Color _ink(BadgeTone t) => switch (t) {
        BadgeTone.green => AppColors.success,
        BadgeTone.gold => AppColors.goldDark,
        BadgeTone.red => AppColors.error,
        BadgeTone.gray => AppColors.navy,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parking Zones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Where you can park',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Campus parking is divided into zones by type of vehicle.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            for (final z in _zones)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _tint(z.tone),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          z.mark,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink(z.tone),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              z.title,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            StatusBadge(text: z.vehicles, tone: z.tone),
                            const SizedBox(height: 8),
                            Text(
                              z.body,
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
            const SizedBox(height: 4),
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
                      'The Campus Security Office assigns your zone when your permit is approved. You can see your zone in Permit Details. A campus map with the exact locations will be added later.',
                      style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'View My Permit',
              showArrow: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.permitDetails),
            ),
          ],
        ),
      ),
    );
  }
}