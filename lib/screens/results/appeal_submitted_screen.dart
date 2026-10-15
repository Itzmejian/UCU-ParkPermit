import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/date_format.dart';
import '../../models/application_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/notice_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_timeline.dart';
import '../home/home_cards.dart';

class AppealSubmittedScreen extends StatelessWidget {
  const AppealSubmittedScreen({super.key});

  Widget _row(String label, String value, {bool mono = false, Color? color, bool last = false}) {
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
            width: 118,
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

  Widget _recordRow(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, size: 20, color: AppColors.success),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appeal = ApplicationStore.instance.lastAppeal;
    final arg = ModalRoute.of(context)?.settings.arguments;
    final ticket = arg is String ? arg : (appeal?.ticketNo ?? 'APL-2026-0142');
    final when = appeal?.submittedAt ?? DateTime.now();
    final appRef = appeal?.applicationRef ?? 'UCU-APP-2026-0142';
    final files = appeal?.files ?? const <String>[];
    final statementLength = appeal?.statementLength ?? 0;
    final recordCount = files.length + (statementLength > 0 ? 1 : 0);

    return Scaffold(
      appBar: const NoticeAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconBadge(
                  icon: Icons.assignment_turned_in_outlined,
                  size: 92,
                  background: AppColors.goldLight,
                  foreground: AppColors.navy,
                ),
              ),
              const SizedBox(height: 14),
              const Center(
                child: StatusBadge(text: 'UNDER RE-EVALUATION', tone: BadgeTone.gold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Appeal & Resubmission Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your updated documents and appeal were sent to the Campus Safety and Security Office.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'APPEAL TICKET ID',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      ticket,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row('Application Ref', appRef, mono: true),
                    _row('Submitted', '${formatLongDate(when)}  \u2022  ${formatTime(when)}'),
                    _row('Assigned to', 'Campus Security Office'),
                    _row(
                      'Expected time',
                      '24 to 48 business hours',
                      color: AppColors.goldDark,
                      last: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const TimelineCard(
                caption: 'REVIEW PIPELINE',
                title: 'Appeal progress',
                subtitle: 'We will notify you when something changes.',
                items: [
                  TimelineItem(
                    title: 'Appeal received and logged',
                    subtitle: 'Recorded in the official campus docket.',
                    state: TimelineState.done,
                  ),
                  TimelineItem(
                    title: 'Security review in progress',
                    subtitle: 'An officer is validating your updated documents.',
                    state: TimelineState.current,
                    tag: 'IN PROGRESS',
                  ),
                  TimelineItem(
                    title: 'Decision and permit activation',
                    subtitle: 'You will be notified when a decision is made.',
                    state: TimelineState.pending,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Resubmitted records',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        StatusBadge(
                          text: '$recordCount ${recordCount == 1 ? 'ITEM' : 'ITEMS'}',
                          tone: BadgeTone.gray,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (recordCount == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No records to show.',
                          style: TextStyle(fontSize: 13, color: AppColors.textHint),
                        ),
                      ),
                    for (final f in files) _recordRow(Icons.description_outlined, f, 'Uploaded'),
                    if (statementLength > 0)
                      _recordRow(
                        Icons.edit_note_outlined,
                        'Statement of appeal',
                        '$statementLength characters',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: AppColors.navy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temporary parking restriction',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Until your appeal is decided, use the temporary visitor parking bays. You will get an in-app notification once your appeal has been evaluated.',
                            style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Back to Dashboard',
                showArrow: true,
                onPressed: () => Navigator.popUntil(
                  context,
                  (r) => r.settings.name == AppRoutes.home,
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.applicationStatus),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text(
                  'View Appeal Details',
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