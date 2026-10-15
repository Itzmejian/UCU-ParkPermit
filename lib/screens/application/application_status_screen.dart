import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/date_format.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_timeline.dart';
import '../home/home_cards.dart';

class _Info {
  const _Info(this.icon, this.title, this.badge, this.tone, this.message);

  final IconData icon;
  final String title;
  final String badge;
  final BadgeTone tone;
  final String message;
}

class ApplicationStatusScreen extends StatelessWidget {
  const ApplicationStatusScreen({super.key});

  _Info _info(PermitStatus s) {
    return switch (s) {
      PermitStatus.none => const _Info(Icons.info_outline, 'No application', 'NONE', BadgeTone.gray, 'You have not submitted an application yet.'),
      PermitStatus.draft => const _Info(Icons.edit_note_outlined, 'Application draft', 'DRAFT', BadgeTone.gray, 'Your application is saved as a draft.'),
      PermitStatus.pending => const _Info(Icons.hourglass_top_rounded, 'Application submitted', 'PENDING', BadgeTone.gold, 'We received your application. It is waiting in the review queue.'),
      PermitStatus.underReview => const _Info(Icons.manage_search_rounded, 'Under review', 'UNDER REVIEW', BadgeTone.gold, 'An officer is checking your documents. This usually takes 24 to 48 hours.'),
      PermitStatus.declined => const _Info(Icons.cancel_outlined, 'Application declined', 'DECLINED', BadgeTone.red, 'Your application needs a correction. You can file an appeal within 7 days.'),
      PermitStatus.appealReview => const _Info(Icons.schedule_rounded, 'Appeal under review', 'UNDER RE-EVALUATION', BadgeTone.gold, 'Your appeal and corrected documents are being reviewed.'),
      PermitStatus.approved => const _Info(Icons.verified_outlined, 'Permit approved', 'APPROVED', BadgeTone.green, 'Your permit was approved. Your sticker is being prepared.'),
      PermitStatus.stickerReady => const _Info(Icons.inventory_2_outlined, 'Sticker ready', 'READY FOR PICKUP', BadgeTone.gold, 'Claim your permit sticker at the Campus Security Office.'),
      PermitStatus.active => const _Info(Icons.check_circle_outline, 'Permit active', 'ACTIVE', BadgeTone.green, 'Your sticker is claimed and your permit is valid.'),
      PermitStatus.expiringSoon => const _Info(Icons.notification_important_outlined, 'Permit expiring soon', 'EXPIRING', BadgeTone.gold, 'Renew your permit so you can keep parking on campus.'),
      PermitStatus.expired => const _Info(Icons.event_busy_outlined, 'Permit expired', 'EXPIRED', BadgeTone.red, 'Your permit has expired. Renew it to park on campus again.'),
    };
  }

  int _stage(PermitStatus s) {
    return switch (s) {
      PermitStatus.none || PermitStatus.draft || PermitStatus.pending => 0,
      PermitStatus.underReview => 1,
      PermitStatus.declined || PermitStatus.approved || PermitStatus.appealReview => 2,
      PermitStatus.stickerReady => 3,
      PermitStatus.active || PermitStatus.expiringSoon || PermitStatus.expired => 4,
    };
  }

  List<TimelineItem> _timeline(PermitStatus s) {
    if (s == PermitStatus.appealReview) {
      return const [
        TimelineItem(
          title: 'Application submitted',
          subtitle: 'Your vehicle details and documents were received.',
          state: TimelineState.done,
        ),
        TimelineItem(
          title: 'Security Office review',
          subtitle: 'Your documents were checked.',
          state: TimelineState.done,
        ),
        TimelineItem(
          title: 'Decision: declined',
          subtitle: 'You were asked to fix some documents.',
          state: TimelineState.done,
        ),
        TimelineItem(
          title: 'Appeal and documents resubmitted',
          subtitle: 'Your replacement documents were uploaded.',
          state: TimelineState.done,
        ),
        TimelineItem(
          title: 'Re-evaluation',
          subtitle: 'An officer is validating your updated documents.',
          state: TimelineState.current,
          tag: 'IN PROGRESS (24-48 HRS)',
        ),
        TimelineItem(
          title: 'Decision and sticker',
          subtitle: 'You will be notified once a decision is made.',
          state: TimelineState.pending,
        ),
      ];
    }

    final stage = _stage(s);
    final declined = s == PermitStatus.declined;

    final String reviewSub = stage == 0
        ? 'Waiting for an officer to pick up your application.'
        : (stage == 1
            ? 'An officer is checking your documents.'
            : 'Your documents were checked.');
    final TimelineState reviewState = stage == 0
        ? TimelineState.pending
        : (stage == 1 ? TimelineState.current : TimelineState.done);

    final String decisionTitle = declined
        ? 'Decision: declined'
        : (stage >= 2 ? 'Decision: approved' : 'Decision');
    final String decisionSub = declined
        ? 'See the remarks and file an appeal within 7 days.'
        : (stage >= 2
            ? 'Your permit number was issued.'
            : 'You will be notified once a decision is made.');
    final TimelineState decisionState = stage < 2
        ? TimelineState.pending
        : (declined ? TimelineState.current : TimelineState.done);

    String stickerSub = 'After approval, claim your permit sticker at the Security Office.';
    TimelineState stickerState = TimelineState.pending;
    String? stickerTag;
    if (!declined && stage == 2) {
      stickerSub = 'Your sticker is being prepared.';
      stickerState = TimelineState.current;
      stickerTag = 'PREPARING';
    } else if (stage == 3) {
      stickerSub = 'Ready for pickup at the Campus Security Office.';
      stickerState = TimelineState.current;
      stickerTag = 'READY';
    } else if (stage == 4) {
      stickerSub = 'Sticker claimed. Keep it on your vehicle.';
      stickerState = TimelineState.done;
    }

    return [
      const TimelineItem(
        title: 'Application submitted',
        subtitle: 'Your vehicle details and documents were received.',
        state: TimelineState.done,
      ),
      TimelineItem(
        title: 'Security Office review',
        subtitle: reviewSub,
        state: reviewState,
        tag: stage == 1 ? 'IN PROGRESS (24-48 HRS)' : null,
      ),
      TimelineItem(
        title: decisionTitle,
        subtitle: decisionSub,
        state: decisionState,
        tag: declined ? 'DECLINED' : null,
      ),
      TimelineItem(
        title: 'Sticker pickup',
        subtitle: stickerSub,
        state: stickerState,
        tag: stickerTag,
      ),
    ];
  }

  Widget _detailRow(String label, String value, {bool last = false, bool mono = false}) {
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
            width: 108,
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
                color: AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, PermitStatus s) {
    final draft = s == PermitStatus.draft;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(icon: Icons.receipt_long_outlined),
            const SizedBox(height: 20),
            Text(
              draft ? 'Your application is a draft' : 'No submitted application yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              draft
                  ? 'Finish and submit your application to start the review.'
                  : 'Start an application to get your parking permit.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Back to Home',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ApplicationStore.instance;
    final status = store.status;
    final noApplication =
        status == PermitStatus.none || status == PermitStatus.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Application Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: noApplication ? _empty(context, status) : _content(context, status),
      ),
    );
  }

  Widget _content(BuildContext context, PermitStatus status) {
    final store = ApplicationStore.instance;
    final info = _info(status);
    final app = MockApplication.resolve(status);
    final sub = store.submitted;
    final submittedOn = sub != null ? formatLongDate(sub.submittedAt) : 'October 24, 2026';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        StatusSummaryCard(
          icon: info.icon,
          title: info.title,
          badgeText: info.badge,
          tone: info.tone,
          message: info.message,
          reference: app.referenceNo,
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'APPLICATION DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 6),
              _detailRow('Submitted on', submittedOn),
              _detailRow('Vehicle', app.vehicleName),
              _detailRow('Plate Number', app.plate, mono: true),
              _detailRow('Type', app.vehicleType, last: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TimelineCard(
          caption: 'PROGRESS',
          title: 'Where your application is',
          subtitle: 'We will notify you when something changes.',
          items: _timeline(status),
        ),
        const SizedBox(height: 16),
        ..._actions(context, status),
        const SizedBox(height: 12),
        HelpLinkCard(
          onTap: () => Navigator.pushNamed(context, AppRoutes.permitRequirements),
        ),
      ],
    );
  }

  List<Widget> _actions(BuildContext context, PermitStatus s) {
    if (s == PermitStatus.declined) {
      return [
        PrimaryButton(
          label: 'File an Appeal & Resubmit Docs',
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.appeal),
        ),
      ];
    }
    if (s == PermitStatus.stickerReady) {
      return [
        PrimaryButton(
          label: 'View Pickup Details',
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.stickerPickup),
        ),
      ];
    }
    if (s == PermitStatus.expiringSoon || s == PermitStatus.expired) {
      return [
        PrimaryButton(
          label: 'Renew Permit',
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.renewal),
        ),
      ];
    }
    if (_stage(s) >= 2 && s != PermitStatus.appealReview) {
      return [
        PrimaryButton(
          label: 'View Permit Details',
          showArrow: true,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.permitDetails),
        ),
      ];
    }
    return const <Widget>[];
  }
}