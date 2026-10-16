import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import 'vehicle_ui.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.isPrimary,
    required this.onDetails,
    this.actionLabel,
    this.onAction,
  });

  final VehicleRecord vehicle;
  final bool isPrimary;
  final VoidCallback onDetails;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final badge = badgeFor(vehicle);
    final moto = vehicle.type == VehicleType.motorcycle;
    final color = vehicle.draft.color.trim();
    final subtitle = '${vehicle.type.label}  \u2022  ${color.isEmpty ? '-' : color}';
    final label = '${isPrimary ? 'PRIMARY' : 'SECONDARY'} \u2022 ${moto ? '2-WHEEL' : '4-WHEEL'}';

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              StatusBadge(text: label, tone: BadgeTone.gray),
              StatusBadge(text: badge.text, tone: badge.tone),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _PlateBox(plate: vehicle.plate, moto: moto),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              vehicleInfoText(vehicle),
              style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (actionLabel != null && onAction != null) ...[
                Expanded(
                  child: _ActionButton(label: actionLabel!, onPressed: onAction!, filled: true),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _ActionButton(label: 'Details', onPressed: onDetails),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlateBox extends StatelessWidget {
  const _PlateBox({required this.plate, required this.moto});

  final String plate;
  final bool moto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.navy, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            moto ? 'MC PLATE' : 'PHILIPPINES',
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textHint,
            ),
          ),
          Text(
            plate.isEmpty ? '-' : plate,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return SizedBox(
      height: 44,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: shape,
              ),
              child: Text(label, style: textStyle),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                side: const BorderSide(color: AppColors.navy, width: 1.2),
                shape: shape,
              ),
              child: Text(label, style: textStyle),
            ),
    );
  }
}