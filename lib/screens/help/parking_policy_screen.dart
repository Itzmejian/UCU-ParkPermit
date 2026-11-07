import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/app_routes.dart';
import '../../services/campus_info_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';

class ParkingPolicyScreen extends StatefulWidget {
  const ParkingPolicyScreen({super.key});

  @override
  State<ParkingPolicyScreen> createState() => _ParkingPolicyScreenState();
}

class _ParkingPolicyScreenState extends State<ParkingPolicyScreen> {
  static const List<CampusRule> _builtIn = [
    CampusRule(Icons.directions_car_outlined, 'Up to $kMaxVehicles vehicles',
        'Each account can register up to $kMaxVehicles vehicles. A pending application counts as one.'),
    CampusRule(Icons.confirmation_number_outlined, 'Permit sticker',
        'After approval you get a parking sticker with a QR code. Put it on your vehicle where the guard can see it. The guard scans it at the gate.'),
    CampusRule(Icons.do_not_disturb_on_outlined, 'Stickers are not transferable',
        'A sticker belongs to one vehicle and one person. Do not lend it or move it to another vehicle.'),
    CampusRule(Icons.event_available_outlined, 'Valid for one semester',
        'A permit is valid for one semester (6 months). The date is shown in Permit Details. Renew before it expires.'),
    CampusRule(Icons.local_parking, 'Without a valid permit',
        'Use the temporary visitor parking bays until your permit is approved or renewed.'),
    CampusRule(Icons.edit_note_outlined, 'Changes to your vehicle',
        'A new plate number must be verified again by the Security Office. Changes to the make or model, color and year are saved right away.'),
    CampusRule(Icons.gavel_outlined, 'Declined applications',
        'You have 7 days to file one appeal and resubmit the documents that need correcting.'),
    CampusRule(Icons.autorenew_rounded, 'Lost or damaged sticker',
        'Request a replacement in Permit Details. The old sticker stops working once the replacement is approved.'),
    CampusRule(Icons.lock_outline, 'Your documents and data',
        'Your documents are used only for your parking permit and are handled under the Data Privacy Act of 2012 (RA 10173).'),
  ];

  List<CampusRule>? _rules;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await CampusInfoService.rules();
    if (!mounted) return;
    setState(() {
      _rules = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules ?? _builtIn;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const Text(
                'Campus parking rules',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'The rules set by the Campus Security Office.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
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
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  r.body,
                                  style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (!_loading && _rules == null)
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
                      Icon(Icons.cloud_off_outlined, size: 20, color: AppColors.goldDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Showing the saved copy. Pull down to load the latest rules when you are online.',
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
      ),
    );
  }
}