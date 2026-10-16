import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/step_timeline.dart';
import '../home/home_cards.dart';

class StickerPickupScreen extends StatelessWidget {
  const StickerPickupScreen({super.key});

  int? _stage(PermitStatus s) {
    return switch (s) {
      PermitStatus.approved => 0,
      PermitStatus.stickerReady => 1,
      PermitStatus.active || PermitStatus.expiringSoon || PermitStatus.expired => 2,
      _ => null,
    };
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(icon: Icons.inventory_2_outlined),
            const SizedBox(height: 20),
            const Text(
              'No sticker yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your sticker is prepared after your permit is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ApplicationStore.instance.status;
    final stage = _stage(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sticker Pickup',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: stage == null ? _empty(context) : _content(context, status, stage),
      ),
    );
  }

  Widget _content(BuildContext context, PermitStatus status, int stage) {
    final app = MockApplication.resolve(status);

    final items = [
      TimelineItem(
        title: 'Sticker being prepared',
        subtitle: 'The Security Office prints your permit sticker.',
        state: stage == 0 ? TimelineState.current : TimelineState.done,
        tag: stage == 0 ? 'IN PROGRESS' : null,
      ),
      TimelineItem(
        title: 'Ready for pickup',
        subtitle: 'You will get a notification when it is ready.',
        state: stage == 0
            ? TimelineState.pending
            : (stage == 1 ? TimelineState.current : TimelineState.done),
        tag: stage == 1 ? 'READY' : null,
      ),
      TimelineItem(
        title: 'Sticker claimed',
        subtitle: 'Put the sticker on your vehicle.',
        state: stage == 2 ? TimelineState.done : TimelineState.pending,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (stage == 1)
          const PickupBanner()
        else if (stage == 2)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You already claimed your sticker.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (stage != 0) const SizedBox(height: 12),
        TimelineCard(
          caption: 'STICKER STATUS',
          title: 'Where your sticker is',
          subtitle: 'We will notify you when it changes.',
          items: items,
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WHERE AND WHEN TO CLAIM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 6),
              _infoRow(Icons.apartment_outlined, 'Office', 'Campus Security Office'),
              _infoRow(Icons.meeting_room_outlined, 'Location', 'Room 102, Admin Building'),
              _infoRow(Icons.schedule, 'Hours', '8 AM to 5 PM'),
              _infoRow(Icons.badge_outlined, 'Bring', 'Your UCU ID'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR PERMIT NUMBER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.permitNo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Show this number when you claim your sticker.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'View Permit Details',
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.permitDetails),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Back',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}