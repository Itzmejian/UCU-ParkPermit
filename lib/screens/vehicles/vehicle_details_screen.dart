import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../core/date_format.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/status_badge.dart';
import 'vehicle_ui.dart';

class VehicleDetailsScreen extends StatelessWidget {
  const VehicleDetailsScreen({super.key});

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

  Widget _row(String label, String value, {bool mono = false, bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow(String label, PickedDoc? doc, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(
            doc == null ? Icons.remove_circle_outline : Icons.check_circle,
            size: 18,
            color: doc == null ? AppColors.textHint : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  doc == null ? 'Not uploaded' : doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          if (doc != null)
            const StatusBadge(text: 'UPLOADED', tone: BadgeTone.green),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, VehicleRecord v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this vehicle?'),
        content: Text(
          '${v.plate} will be removed from your account and one vehicle slot will be freed. If it has a valid permit, you will need to apply again to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (DataService.live) {
      final r = await DataService.removeVehicle(v);
      if (!r.ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(r.error ?? 'Could not remove the vehicle.')),
        );
        return;
      }
    } else {
      ApplicationStore.instance.removeVehicle(v.id);
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Vehicle removed. One slot is free again.')),
    );
  }

  Widget _notFound(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IconBadge(icon: Icons.directions_car_outlined),
              const SizedBox(height: 16),
              const Text(
                'Vehicle not found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Back', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, VehicleRecord v, bool primary) {
    final widgets = <Widget>[];
    final s = v.status;

    if (primary) {
      final action = vehiclePrimaryAction(s);
      if (action != null) {
        widgets.add(PrimaryButton(
          label: action.$1,
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, action.$2),
        ));
        widgets.add(const SizedBox(height: 10));
      }
    }

    final canUpdate = canRequestUpdate(s) && !v.pendingVerification;
    widgets.add(SecondaryButton(
      label: 'Request Update',
      onPressed: canUpdate
          ? () => Navigator.pushNamed(context, AppRoutes.vehicleUpdate, arguments: v.id)
          : null,
    ));

    String? note;
    if (v.pendingVerification) {
      note = 'You can request another update after the current one is verified.';
    } else if (s == PermitStatus.expired) {
      note = 'Renew your permit first before changing vehicle details.';
    } else if (!canRequestUpdate(s)) {
      note = 'You can request an update after your application is decided.';
    }
    if (note != null) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          note,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
        ),
      ));
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final store = ApplicationStore.instance;
    final arg = ModalRoute.of(context)?.settings.arguments;
    final id = arg is int ? arg : 0;

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final v = store.vehicleById(id);
        if (v == null) return _notFound(context);

        final primary = store.isPrimary(v.id);
        final badge = badgeFor(v);
        final moto = v.type == VehicleType.motorcycle;
        final app = MockApplication.forVehicle(v);
        final showPermit = hasPermitNumber(v.status);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Vehicle Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${primary ? 'PRIMARY' : 'SECONDARY'} \u2022 ${moto ? '2-WHEEL' : '4-WHEEL'}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Color(0xFFB7C6EC),
                            ),
                          ),
                          StatusBadge(text: badge.text, tone: badge.tone),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v.plate.isEmpty ? '-' : v.plate,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.title,
                        style: const TextStyle(fontSize: 14, color: Color(0xFFB7C6EC)),
                      ),
                    ],
                  ),
                ),
                if (v.pendingVerification) ...[
                  const SizedBox(height: 12),
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
                        Icon(Icons.hourglass_top_rounded, size: 20, color: AppColors.goldDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your update is waiting for verification by the Security Office. This usually takes about 24 hours.',
                            style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption('VEHICLE INFORMATION'),
                      const SizedBox(height: 4),
                      _row('Type', v.type.label),
                      _row('Make / Model', v.makeModel),
                      _row('Color', v.draft.color.trim()),
                      _row('Model year', v.draft.modelYear.trim()),
                      _row('Registered on', formatLongDate(v.registeredAt), last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption(showPermit ? 'PERMIT' : 'APPLICATION'),
                      const SizedBox(height: 4),
                      if (showPermit) ...[
                        _row('Permit no.', app.permitNo, mono: true),
                        _row('Parking zone', app.zone),
                        _row('Valid until', app.validUntil),
                      ],
                      _row('Reference no.', v.referenceNo, mono: true),
                      _row('Status', badge.text, last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _caption('DOCUMENTS'),
                      const SizedBox(height: 4),
                      _docRow("Driver's License", v.draft.license),
                      _docRow('Vehicle OR/CR', v.draft.orcr),
                      _docRow('UCU ID', v.draft.ucuId, last: true),
                    ],
                  ),
                ),
                if (!primary) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Full tracking screens for your additional vehicles will be completed when the app is connected to the server.',
                      style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ..._actions(context, v, primary),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _confirmRemove(context, v),
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  label: const Text(
                    'Remove Vehicle',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                ),
                if (kShowDevTools && !AuthService.live && v.pendingVerification)
                  TextButton(
                    onPressed: () => store.markVerified(v.id),
                    child: const Text(
                      'Testing: mark update as verified',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}