import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/application_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/ucu_logo.dart';

class ApplicationSubmittedScreen extends StatelessWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    final ref = arg is String
        ? arg
        : (ApplicationStore.instance.submitted?.referenceNo ?? 'UCU-APP-0000-0000');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            UcuLogo(size: 30),
            SizedBox(width: 10),
            Text(
              'UCU ParkPermit',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == AppRoutes.home),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldLight,
                    border: Border.all(color: AppColors.gold, width: 8),
                  ),
                  child: const Icon(Icons.check_rounded, size: 52, color: AppColors.goldDark),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Application submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "You'll be notified once it's reviewed.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tag, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        const Text(
                          'Reference No.',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          ref,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            fontFamily: 'monospace',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.navy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: ref));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reference number copied')),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 22, color: AppColors.border),
                    const _InfoRow(
                      icon: Icons.schedule,
                      title: 'Estimated review time',
                      body: '24 to 48 office hours by the Campus Safety and Security Office.',
                    ),
                    const SizedBox(height: 14),
                    const _InfoRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'How you will be notified',
                      body: 'An in-app notification will appear in the bell on your Home screen.',
                    ),
                    const SizedBox(height: 14),
                    const StatusBadge(text: 'QUEUED FOR REVIEW', tone: BadgeTone.gold),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Back to Home',
                showArrow: true,
                onPressed: () => Navigator.popUntil(context, (r) => r.settings.name == AppRoutes.home),
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.applicationStatus),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text(
                  'Track Application Status',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
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
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}