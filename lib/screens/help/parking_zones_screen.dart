import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../services/campus_info_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class ParkingZonesScreen extends StatefulWidget {
  const ParkingZonesScreen({super.key});

  @override
  State<ParkingZonesScreen> createState() => _ParkingZonesScreenState();
}

class _ParkingZonesScreenState extends State<ParkingZonesScreen> {
  static const List<CampusZone> _builtIn = [
    CampusZone('A-C', 'Zones A, B and C', 'four_wheel',
        'Parking lots for sedans, hatchbacks, SUVs, MPVs and pickups.'),
    CampusZone('M', 'Zone M', 'motorcycle', 'Parking bays for scooters, mopeds, underbones and big bikes.'),
    CampusZone('V', 'Visitor parking bays', 'visitor',
        'Temporary bays for vehicles without an approved permit, such as while your application is pending or after your permit expired.'),
  ];

  List<CampusZone>? _zones;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final z = await CampusInfoService.zones();
    if (!mounted) return;
    setState(() {
      _zones = z;
      _loading = false;
    });
  }

  BadgeTone _tone(String type) => switch (type) {
        'motorcycle' => BadgeTone.gold,
        'visitor' => BadgeTone.gray,
        _ => BadgeTone.green,
      };

  String _label(String type) => switch (type) {
        'motorcycle' => 'MOTORCYCLES',
        'visitor' => 'NO PERMIT YET',
        _ => '4-WHEEL VEHICLES',
      };

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
    final zones = _zones ?? _builtIn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Zones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'Where you can park',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Campus parking is divided into zones by type of vehicle.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final z in zones)
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
                              color: _tint(_tone(z.vehicleType)),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              z.code,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink(_tone(z.vehicleType))),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  z.name,
                                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 6),
                                StatusBadge(text: _label(z.vehicleType), tone: _tone(z.vehicleType)),
                                if (z.description.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    z.description,
                                    style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted),
                                  ),
                                ],
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
                        'The Campus Security Office assigns your zone when your permit is approved. You can see your zone in Permit Details and on your sticker.',
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
      ),
    );
  }
}