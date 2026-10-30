import 'package:flutter/material.dart';
import '../../widgets/appeal_window.dart';
import '../../core/app_colors.dart';
import '../../models/mock_application.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_timeline.dart';

class GreetingBanner extends StatelessWidget {
  const GreetingBanner({super.key, required this.name, required this.roleLabel});

  final String name;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_outlined, size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hello, $name!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Campus Parking Access & Permit Services',
            style: TextStyle(fontSize: 13, color: Color(0xFFB7C6EC)),
          ),
        ],
      ),
    );
  }
}

class TermInfoRow extends StatelessWidget {
  const TermInfoRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InfoTile(
              label: 'Academic Term',
              value: 'A.Y. 2026\u20132027',
              sub: '1st Semester',
              icon: Icons.calendar_month_outlined,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _InfoTile(
              label: 'Processing Speed',
              value: '24\u201348 Hours',
              sub: 'Campus Security Office',
              icon: Icons.bolt_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
  });

  final String label;
  final String value;
  final String sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              Icon(icon, size: 18, color: AppColors.goldDark),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

class StatusSummaryCard extends StatelessWidget {
  const StatusSummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.badgeText,
    required this.tone,
    required this.message,
    this.reference,
  });

  final IconData icon;
  final String title;
  final String badgeText;
  final BadgeTone tone;
  final String message;
  final String? reference;

  Color get _accent => switch (tone) {
        BadgeTone.gold => AppColors.gold,
        BadgeTone.green => AppColors.success,
        BadgeTone.red => AppColors.error,
        BadgeTone.gray => AppColors.border,
      };

  Color get _tint => switch (tone) {
        BadgeTone.gold => AppColors.goldLight,
        BadgeTone.green => AppColors.successLight,
        BadgeTone.red => AppColors.errorLight,
        BadgeTone.gray => AppColors.inputFill,
      };

  Color get _iconColor => switch (tone) {
        BadgeTone.gold => AppColors.goldDark,
        BadgeTone.green => AppColors.success,
        BadgeTone.red => AppColors.error,
        BadgeTone.gray => AppColors.navy,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: _tint, shape: BoxShape.circle),
                child: Icon(icon, size: 24, color: _iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(text: badgeText, tone: tone),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
          if (reference != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reference No.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    reference!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class HowToCard extends StatelessWidget {
  const HowToCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Caption('SIMPLE 3-STEP PROCESS'),
          SizedBox(height: 6),
          Text(
            'How to get your parking permit',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Follow these steps to get your campus parking permit.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          SizedBox(height: 16),
          StepTimeline(
            items: [
              TimelineItem(
                title: 'Fill out vehicle details',
                subtitle:
                    'Provide your plate number, vehicle make and model, and category.',
                state: TimelineState.info,
                chips: ['Motorcycle', '4-Wheel'],
              ),
              TimelineItem(
                title: 'Upload your documents',
                subtitle:
                    "Submit your vehicle OR/CR, valid driver's license and UCU ID.",
                state: TimelineState.info,
                chips: ['Clear photo or PDF'],
              ),
              TimelineItem(
                title: 'Wait for approval, then claim your sticker',
                subtitle:
                    'The Security Office checks your files within 24 to 48 hours. When approved, claim your permit sticker with your permit number.',
                state: TimelineState.info,
                chips: ['Permit sticker pickup'],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimelineCard extends StatelessWidget {
  const TimelineCard({
    super.key,
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String caption;
  final String title;
  final String subtitle;
  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Caption(caption),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          StepTimeline(items: items),
        ],
      ),
    );
  }
}

class PermitDetailsCard extends StatelessWidget {
  const PermitDetailsCard({
    super.key,
    required this.app,
    this.expired = false,
    this.expiringSoon = false,
  });

  final MockApplication app;
  final bool expired;
  final bool expiringSoon;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Permit No.', app.permitNo),
      MapEntry('Vehicle', app.vehicleName),
      MapEntry('Plate Number', app.plate),
      MapEntry('Type', app.vehicleType),
      MapEntry('Parking Zone', app.zone),
      MapEntry('Valid Until', app.validUntil),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_car_outlined, size: 18, color: AppColors.navy),
              SizedBox(width: 8),
              _Caption('PERMIT AND VEHICLE'),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++)
            _DetailRow(
              label: rows[i].key,
              value: rows[i].value,
              last: i == rows.length - 1,
              mono: rows[i].key == 'Permit No.' || rows[i].key == 'Plate Number',
              valueColor: rows[i].key == 'Valid Until'
                  ? (expired
                      ? AppColors.error
                      : (expiringSoon ? AppColors.goldDark : null))
                  : null,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.last,
    this.mono = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool last;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
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
                color: valueColor ?? AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DeclinedDetailsCard extends StatelessWidget {
  const DeclinedDetailsCard({super.key, required this.app});

  final MockApplication app;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: const Color(0xFFF2B8B8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, size: 20, color: AppColors.error),
              SizedBox(width: 8),
              Text(
                'What needs to be fixed',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final f in app.flagged)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2B8B8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f.remark,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Caption('NOTE FROM THE SECURITY OFFICE'),
                const SizedBox(height: 6),
                Text(
                  app.officerNote,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppealWindowNotice(referenceNo: app.referenceNo),
        ],
      ),
    );
  }
}

class PickupBanner extends StatelessWidget {
  const PickupBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.4),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.inventory_2_outlined, size: 26, color: AppColors.goldDark),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your permit sticker is ready',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Claim it at the Campus Security Office, Room 102, Admin Building (8 AM to 5 PM). Bring your UCU ID.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
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
}

class HelpLinkCard extends StatelessWidget {
  const HelpLinkCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: const Row(
        children: [
          Icon(Icons.menu_book_outlined, size: 22, color: AppColors.navy),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Need help? Check Permit Requirements & Guidelines',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class VisitorNote extends StatelessWidget {
  const VisitorNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock_outlined, size: 18, color: AppColors.textHint),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vehicles without an approved permit must use the temporary visitor parking bays until approved.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
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
}