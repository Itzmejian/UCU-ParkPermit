import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/app_routes.dart';
import '../../models/application_store.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/status_badge.dart';
import 'vehicle_card.dart';
import 'vehicle_ui.dart';

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  Widget _registerButton(BuildContext context, bool full) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: full ? null : () => Navigator.pushNamed(context, AppRoutes.apply),
        icon: const Icon(Icons.add),
        label: const Text(
          'Register New Vehicle',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.navyDisabled,
          disabledForegroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _policyCard(BuildContext context) {
    const bullet = TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted);
    return AppCard(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.policy_outlined, size: 20, color: AppColors.goldDark),
              SizedBox(width: 8),
              Text(
                'VEHICLE LIMIT & POLICY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'You can register up to $kMaxVehicles vehicles. A pending application counts as one.',
            style: bullet,
          ),
          const SizedBox(height: 6),
          const Text('Stickers are not transferable to another vehicle.', style: bullet),
          const SizedBox(height: 4),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.permitRequirements),
            child: const Text(
              'READ THE PERMIT REQUIREMENTS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ApplicationStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final vehicles = store.vehicles;
        final used = store.slotsUsed;
        final full = store.limitReached;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const StatusBadge(text: 'A.Y. 2026\u20132027', tone: BadgeTone.gold),
                const Spacer(),
                Text(
                  'Slot: $used / $kMaxVehicles used',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Registered Vehicles',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your campus vehicles and their permits.',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            _registerButton(context, full),
            if (full)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'You reached the $kMaxVehicles-vehicle limit. Remove a vehicle to add another one.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textHint),
                ),
              ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    IconBadge(icon: Icons.directions_car_outlined),
                    SizedBox(height: 16),
                    Text(
                      'No vehicles yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Register your first vehicle to apply for a campus parking permit.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            for (int i = 0; i < vehicles.length; i++) ...[
              Builder(
                builder: (context) {
                  final v = vehicles[i];
                  final primary = i == 0;
                  final action = primary ? vehiclePrimaryAction(v.status) : null;
                  return VehicleCard(
                    vehicle: v,
                    isPrimary: primary,
                    actionLabel: action?.$1,
                    onAction: action == null
                        ? null
                        : () => Navigator.pushNamed(context, action.$2),
                    onDetails: () => Navigator.pushNamed(
                      context,
                      AppRoutes.vehicleDetails,
                      arguments: v.id,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            _policyCard(context),
          ],
        );
      },
    );
  }
}