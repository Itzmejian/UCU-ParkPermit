import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/notice_app_bar.dart';
import '../../widgets/status_badge.dart';

class ApplicationApprovedScreen extends StatelessWidget {
  const ApplicationApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MockApplication.resolve(PermitStatus.approved);

    return Scaffold(
      appBar: const NoticeAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: AppColors.inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: 2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.verified, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Application Approved!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your vehicle permit has been officially approved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.navy, AppColors.gold],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'REFERENCE NO.',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    app.referenceNo,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              const StatusBadge(text: 'APPROVED', tone: BadgeTone.green),
                            ],
                          ),
                          const Divider(height: 26, color: AppColors.border),
                          _Block(
                            icon: Icons.directions_car_outlined,
                            label: 'REGISTERED VEHICLE',
                            title: '${app.plate}  \u2022  ${app.vehicleName}',
                            sub: app.vehicleType,
                          ),
                          _Block(
                            icon: Icons.confirmation_number_outlined,
                            label: 'PERMIT NUMBER',
                            title: app.permitNo,
                            sub: 'Printed on your permit sticker',
                            mono: true,
                          ),
                          _Block(
                            icon: Icons.event_available_outlined,
                            label: 'VALIDITY PERIOD',
                            title: 'Valid until ${app.validUntil}',
                            sub: 'A.Y. 2026\u20132027',
                          ),
                          _Block(
                            icon: Icons.local_parking,
                            label: 'ASSIGNED PARKING ZONE',
                            title: app.zone,
                            sub: 'Assigned by the Campus Security Office',
                            last: true,
                          ),
                        ],
                      ),
                    ),
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
                    Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.goldDark),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your permit sticker is being prepared. We will notify you when it is ready for pickup. The sticker shows your permit number.',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 20, color: AppColors.navy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reviewed and approved by the Campus Safety and Security Enforcement Office.',
                        style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'View Permit Details',
                showArrow: true,
                onPressed: () => Navigator.pushNamed(context, AppRoutes.permitDetails),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Return to Dashboard',
                onPressed: () => Navigator.popUntil(
                  context,
                  (r) => r.settings.name == AppRoutes.home,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF download will be added later.')),
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text(
                  'Download Permit Certificate (PDF)',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'UCU Safety & Campus Security Enforcement Office',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.icon,
    required this.label,
    required this.title,
    required this.sub,
    this.mono = false,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String title;
  final String sub;
  final bool mono;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    fontFamily: mono ? 'monospace' : null,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}