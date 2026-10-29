import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_timeline.dart';
import '../../models/application_store.dart';
import '../../models/profile_store.dart';
import 'home_cards.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // TODO: replace with the real status from Supabase.
  PermitStatus _status = ApplicationStore.instance.status;

  @override
  void initState() {
    super.initState();
    ApplicationStore.instance.addListener(_syncFromStore);
  }

  @override
  void dispose() {
    ApplicationStore.instance.removeListener(_syncFromStore);
    super.dispose();
  }

  void _syncFromStore() {
    if (!mounted) return;
    final s = ApplicationStore.instance.status;
    if (s != _status) setState(() => _status = s);
  }

  Future<void> _go(String route) async {
    ApplicationStore.instance.status = _status;
    var target = route;
    if (route == AppRoutes.applicationStatus &&
        _status == PermitStatus.declined) {
      target = AppRoutes.applicationDeclined;
    } else if (route == AppRoutes.permitDetails &&
        _status == PermitStatus.approved) {
      target = AppRoutes.applicationApproved;
    }
    if (route == AppRoutes.renewal && _status == PermitStatus.expired) {
      target = AppRoutes.permitExpired;
    }
    await Navigator.pushNamed(context, target);
    if (!mounted) return;
    setState(() => _status = ApplicationStore.instance.status);
  }

  Future<void> _openWizard() async {
    final store = ApplicationStore.instance;
    store.status = _status;
    await Navigator.pushNamed(context, AppRoutes.apply);
    if (!mounted) return;
    setState(() => _status = store.status);
  }

  void _comingSoon(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _showTerm =>
      _status == PermitStatus.none ||
      _status == PermitStatus.draft ||
      _status == PermitStatus.pending ||
      _status == PermitStatus.underReview ||
      _status == PermitStatus.declined ||
      _status == PermitStatus.appealReview;

  @override
  Widget build(BuildContext context) {
    final app = MockApplication.resolve(_status);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AnimatedBuilder(
          animation: ProfileStore.instance,
          builder: (context, child) => GreetingBanner(
            name: ProfileStore.instance.firstName,
            roleLabel: ProfileStore.instance.roleBadge,
          ),
        ),
        if (kShowDevTools && !AuthService.live) ...[
          const SizedBox(height: 12),
          _DevSwitcher(
            current: _status,
            onChanged: (s) => ApplicationStore.instance.setStatus(s),
          ),
        ],
        const SizedBox(height: 14),
        ..._content(app),
      ],
    );
  }

  List<Widget> _content(MockApplication app) {
    return switch (_status) {
      PermitStatus.none => _noPermit(),
      PermitStatus.draft => _draft(app),
      PermitStatus.pending => _pending(app),
      PermitStatus.underReview => _underReview(app),
      PermitStatus.declined => _declined(app),
      PermitStatus.appealReview => _appealReview(app),
      PermitStatus.approved => _approved(app),
      PermitStatus.stickerReady => _stickerReady(app),
      PermitStatus.active => _active(app),
      PermitStatus.expiringSoon => _expiringSoon(app),
      PermitStatus.expired => _expired(app),
    };
  }

  List<Widget> _help({bool visitorNote = true}) {
    return [
      const SizedBox(height: 12),
      HelpLinkCard(onTap: () => _go(AppRoutes.permitRequirements)),
      if (visitorNote) ...[
        const SizedBox(height: 12),
        const VisitorNote(),
      ],
    ];
  }

  List<Widget> _termRow() {
    return _showTerm
        ? [const TermInfoRow(), const SizedBox(height: 12)]
        : const <Widget>[];
  }

  // ---- states ----

  List<Widget> _noPermit() {
    return [
      const StatusSummaryCard(
        icon: Icons.info_outline,
        title: 'No Active Permit',
        badgeText: 'UNREGISTERED',
        tone: BadgeTone.gold,
        message:
            "You don't have an active campus parking permit yet. Complete your application to park in designated university zones.",
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      const HowToCard(),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Apply for Permit',
        showArrow: true,
        onPressed: _openWizard,
      ),
      ..._help(),
    ];
  }

  List<Widget> _draft(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.edit_note_outlined,
        title: 'Application Draft',
        badgeText: 'DRAFT',
        tone: BadgeTone.gray,
        message:
            'You started an application for ${app.vehicleName} (${app.plate}). Continue where you left off.',
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      PrimaryButton(
        label: 'Continue Application',
        showArrow: true,
        onPressed: _openWizard,
      ),
      ..._help(),
    ];
  }

  List<Widget> _pending(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.hourglass_top_rounded,
        title: 'Application Submitted',
        badgeText: 'PENDING',
        tone: BadgeTone.gold,
        message:
            'We received your application. It is waiting in the review queue.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      const TimelineCard(
        caption: 'APPLICATION PROGRESS',
        title: 'Track your application',
        subtitle: 'We will notify you when something changes.',
        items: [
          TimelineItem(
            title: 'Application submitted',
            subtitle: 'Your vehicle details and documents were received.',
            state: TimelineState.done,
          ),
          TimelineItem(
            title: 'Security Office review',
            subtitle: 'Waiting for an officer to pick up your application.',
            state: TimelineState.pending,
          ),
          TimelineItem(
            title: 'Decision and sticker',
            subtitle: 'You will be notified once a decision is made.',
            state: TimelineState.pending,
          ),
        ],
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Track Application Status',
        showArrow: true,
        onPressed: () => _go(AppRoutes.applicationStatus),
      ),
      ..._help(),
    ];
  }

  List<Widget> _underReview(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.manage_search_rounded,
        title: 'Under Review',
        badgeText: 'UNDER REVIEW',
        tone: BadgeTone.gold,
        message:
            'A Security Office officer is checking your documents. This usually takes 24 to 48 hours.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      const TimelineCard(
        caption: 'APPLICATION PROGRESS',
        title: 'Track your application',
        subtitle: 'We will notify you when something changes.',
        items: [
          TimelineItem(
            title: 'Application submitted',
            subtitle: 'Your vehicle details and documents were received.',
            state: TimelineState.done,
          ),
          TimelineItem(
            title: 'Security Office review',
            subtitle: 'An officer is verifying your documents.',
            state: TimelineState.current,
            tag: 'IN PROGRESS (24-48 HRS)',
          ),
          TimelineItem(
            title: 'Decision and sticker',
            subtitle: 'You will be notified once a decision is made.',
            state: TimelineState.pending,
          ),
        ],
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'View Application Status',
        showArrow: true,
        onPressed: () => _go(AppRoutes.applicationStatus),
      ),
      ..._help(),
    ];
  }

  List<Widget> _declined(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.cancel_outlined,
        title: 'Application Declined',
        badgeText: 'DECLINED',
        tone: BadgeTone.red,
        message:
            'Your application needs a correction before a permit can be issued.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      DeclinedDetailsCard(app: app),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'File an Appeal & Resubmit Docs',
        showArrow: true,
        onPressed: () => _go(AppRoutes.appeal),
      ),
      const SizedBox(height: 10),
      SecondaryButton(
        label: 'View Declined Notice',
        onPressed: () => _go(AppRoutes.applicationStatus),
      ),
      ..._help(),
    ];
  }

  List<Widget> _appealReview(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.schedule_rounded,
        title: 'Appeal Under Review',
        badgeText: 'UNDER RE-EVALUATION',
        tone: BadgeTone.gold,
        message:
            'Your appeal and corrected documents are being reviewed by the Campus Security Office.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      ..._termRow(),
      const TimelineCard(
        caption: 'RE-APPEAL VERIFICATION',
        title: 'Track your appeal',
        subtitle: 'The Security Office is re-checking your documents.',
        items: [
          TimelineItem(
            title: 'Documents resubmitted',
            subtitle: 'Your replacement documents were uploaded.',
            state: TimelineState.done,
            chips: ['Vehicle OR/CR'],
          ),
          TimelineItem(
            title: 'Security officer review',
            subtitle: 'An officer is validating your updated documents.',
            state: TimelineState.current,
            tag: 'IN PROGRESS (24-48 HRS)',
          ),
          TimelineItem(
            title: 'Re-approval and sticker',
            subtitle: 'Once verified, your permit will be issued.',
            state: TimelineState.pending,
          ),
        ],
      ),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'View Appeal Details',
        showArrow: true,
        onPressed: () => _go(AppRoutes.applicationStatus),
      ),
      ..._help(),
    ];
  }

  List<Widget> _approved(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.verified_outlined,
        title: 'Permit Approved',
        badgeText: 'APPROVED',
        tone: BadgeTone.green,
        message:
            'Your permit has been approved. Your permit sticker is being prepared. We will notify you when it is ready for pickup.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      PermitDetailsCard(app: app),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'View Permit Details',
        showArrow: true,
        onPressed: () => _go(AppRoutes.permitDetails),
      ),
      ..._help(visitorNote: false),
    ];
  }

  List<Widget> _stickerReady(MockApplication app) {
    return [
      const PickupBanner(),
      const SizedBox(height: 12),
      PermitDetailsCard(app: app),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'View Pickup Details',
        showArrow: true,
        onPressed: () => _go(AppRoutes.stickerPickup),
      ),
      const SizedBox(height: 10),
      SecondaryButton(
        label: 'View Permit Details',
        onPressed: () => _go(AppRoutes.permitDetails),
      ),
      ..._help(visitorNote: false),
    ];
  }

  List<Widget> _active(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.check_circle_outline,
        title: 'Permit Active',
        badgeText: 'ACTIVE',
        tone: BadgeTone.green,
        message:
            'Your sticker is claimed and your permit is valid. Keep the sticker on your vehicle.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      PermitDetailsCard(app: app),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'View Permit Details',
        showArrow: true,
        onPressed: () => _go(AppRoutes.permitDetails),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextButton.icon(
          onPressed: () => _comingSoon('PDF download will be added later.'),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text(
            'Download Permit Certificate (PDF)',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      ..._help(visitorNote: false),
    ];
  }

  List<Widget> _expiringSoon(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.notification_important_outlined,
        title: 'Permit Expiring Soon',
        badgeText: 'EXPIRING',
        tone: BadgeTone.gold,
        message:
            'Your permit expires on ${app.validUntil}. Renew now so you can keep parking on campus.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      PermitDetailsCard(app: app, expiringSoon: true),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Renew Permit',
        showArrow: true,
        onPressed: () => _go(AppRoutes.renewal),
      ),
      const SizedBox(height: 10),
      SecondaryButton(
        label: 'View Permit Details',
        onPressed: () => _go(AppRoutes.permitDetails),
      ),
      ..._help(visitorNote: false),
    ];
  }

  List<Widget> _expired(MockApplication app) {
    return [
      StatusSummaryCard(
        icon: Icons.event_busy_outlined,
        title: 'Permit Expired',
        badgeText: 'EXPIRED',
        tone: BadgeTone.red,
        message:
            'Your permit expired on ${app.validUntil}. Renew it to park in campus zones again.',
        reference: app.referenceNo,
      ),
      const SizedBox(height: 12),
      PermitDetailsCard(app: app, expired: true),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Renew Permit',
        showArrow: true,
        onPressed: () => _go(AppRoutes.renewal),
      ),
      ..._help(),
    ];
  }
}

/// TESTING ONLY: lets you preview every status. Controlled by kShowDevTools.
class _DevSwitcher extends StatelessWidget {
  const _DevSwitcher({required this.current, required this.onChanged});

  final PermitStatus current;
  final ValueChanged<PermitStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TESTING ONLY: preview a status',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in PermitStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: s == current,
                      showCheckmark: false,
                      selectedColor: AppColors.navy,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s == current ? Colors.white : AppColors.textDark,
                      ),
                      onSelected: (_) => onChanged(s),
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