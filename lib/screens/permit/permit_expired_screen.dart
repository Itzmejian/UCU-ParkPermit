import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/notice_app_bar.dart';
import '../../widgets/status_badge.dart';

class PermitExpiredScreen extends StatelessWidget {
  const PermitExpiredScreen({super.key});

  Widget _row(String label, String value, {bool mono = false, bool last = false, Color? color}) {
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
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = MockApplication.resolve(PermitStatus.expired);

    return Scaffold(
      appBar: const NoticeAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.error, width: 2),
                  ),
                  child: const Icon(Icons.event_busy_outlined, size: 46, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: StatusBadge(text: 'EXPIRED', tone: BadgeTone.red),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your permit has expired',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'It expired on ${app.validUntil}. Renew it to park on campus again.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Permit no.', app.permitNo, mono: true),
                    _row('Vehicle', app.vehicleName),
                    _row('Plate number', app.plate, mono: true),
                    _row('Expired on', app.validUntil, last: true, color: AppColors.error),
                  ],
                ),
              ),
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
                    Icon(Icons.local_parking, size: 20, color: AppColors.goldDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Until you have a new permit, please use the temporary visitor parking bays.',
                        style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Renew Permit',
                showArrow: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.renewal),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Return to Dashboard',
                onPressed: () => Navigator.popUntil(
                  context,
                  (r) => r.settings.name == AppRoutes.home,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}