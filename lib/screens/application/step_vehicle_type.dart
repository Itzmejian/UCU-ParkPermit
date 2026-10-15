import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../models/application_draft.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_footer.dart';

class StepVehicleType extends StatefulWidget {
  const StepVehicleType({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onCancel,
  });

  final ApplicationDraft draft;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  @override
  State<StepVehicleType> createState() => _StepVehicleTypeState();
}

class _StepVehicleTypeState extends State<StepVehicleType> {
  void _select(VehicleType type) {
    setState(() => widget.draft.vehicleType = type);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.draft.vehicleType;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'What type of vehicle are you registering?',
            style: TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select your primary campus vehicle category.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          _VehicleCard(
            icon: Icons.two_wheeler,
            title: 'Motorcycle',
            subtitle: 'Scooter, Moped, Underbone, Big Bike',
            chip: 'HELMET SAFETY REQUIREMENT',
            selected: selected == VehicleType.motorcycle,
            onTap: () => _select(VehicleType.motorcycle),
          ),
          const SizedBox(height: 12),
          _VehicleCard(
            icon: Icons.directions_car,
            title: '4-Wheel Vehicle',
            subtitle: 'Sedan, Hatchback, SUV, MPV, Pickup',
            chip: 'REQUIRES LTO OR/CR',
            selected: selected == VehicleType.fourWheel,
            onTap: () => _select(VehicleType.fourWheel),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.navy),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The Campus Security Office assigns your parking zone when your application is approved. You can register up to $kMaxVehicles vehicles. Add another one later from the Vehicles tab.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          StepFooter(
            primaryLabel: 'Next Step',
            onPrimary: selected == null ? null : widget.onNext,
            secondaryLabel: 'Cancel & Return to Dashboard',
            secondaryIsBack: false,
            onSecondary: widget.onCancel,
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String chip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.inputFill : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.navy : AppColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusBadge(text: chip, tone: BadgeTone.gold),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? AppColors.navy : AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}