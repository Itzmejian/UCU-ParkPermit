import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/notice_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/appeal_window.dart';
import '../home/home_cards.dart';

class ApplicationDeclinedScreen extends StatelessWidget {
  const ApplicationDeclinedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MockApplication.resolve(PermitStatus.declined);

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
                  child: const Icon(Icons.close_rounded, size: 48, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Application Declined',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your permit application needs a correction before a permit can be issued.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reference Number',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                    const StatusBadge(text: 'DECLINED', tone: BadgeTone.red),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DeclinedDetailsCard(app: app),
              const SizedBox(height: 22),
              AppealButton(
                referenceNo: app.referenceNo,
                label: 'File an Appeal & Resubmit Docs',
                onPressed: () => Navigator.pushNamed(context, AppRoutes.appeal),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'View Declined Notice (PDF)',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF notice will be added later.')),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.popUntil(
                  context,
                  (r) => r.settings.name == AppRoutes.home,
                ),
                child: const Text(
                  'Return to Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted),
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