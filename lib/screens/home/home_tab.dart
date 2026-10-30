import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../models/profile_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/appeal_window.dart';
import 'home_cards.dart';

/// The Home tab shows only what the applicant needs right now: the status of
/// the permit and the next thing to do. Details are on their own screens, and
/// the 3-step guide is in Profile > Help & Support.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
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
      PermitStatus.none => [
          const StatusSummaryCard(
            icon: Icons.info_outline,
            title: 'No Active Permit',
            badgeText: 'UNREGISTERED',
            tone: BadgeTone.gold,
            message:
                'Apply for a parking permit to park in the campus parking zones.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Apply for Permit',
            showArrow: true,
            onPressed: _openWizard,
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _go(AppRoutes.help),
              child: const Text(
                'How does it work?',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ),
          ),
        ],
      PermitStatus.draft => [
          StatusSummaryCard(
            icon: Icons.edit_note_outlined,
            title: 'Application Draft',
            badgeText: 'DRAFT',
            tone: BadgeTone.gray,
            message:
                'Your application for ${app.vehicleName} (${app.plate}) is saved. Continue where you left off.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Continue Application',
            showArrow: true,
            onPressed: _openWizard,
          ),
        ],
      PermitStatus.pending => [
          StatusSummaryCard(
            icon: Icons.hourglass_top_rounded,
            title: 'Application Submitted',
            badgeText: 'PENDING',
            tone: BadgeTone.gold,
            message:
                'Your application is waiting for review. We will notify you when it changes.',
            reference: app.referenceNo,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Track Application',
            showArrow: true,
            onPressed: () => _go(AppRoutes.applicationStatus),
          ),
        ],
      PermitStatus.underReview => [
          StatusSummaryCard(
            icon: Icons.manage_search_rounded,
            title: 'Under Review',
            badgeText: 'UNDER REVIEW',
            tone: BadgeTone.gold,
            message:
                'An officer is checking your documents. This takes 24 to 48 hours.',
            reference: app.referenceNo,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Track Application',
            showArrow: true,
            onPressed: () => _go(AppRoutes.applicationStatus),
          ),
        ],
      PermitStatus.declined => [
          StatusSummaryCard(
            icon: Icons.cancel_outlined,
            title: 'Application Declined',
            badgeText: 'DECLINED',
            tone: BadgeTone.red,
            message: 'Fix the items below, then file an appeal.',
            reference: app.referenceNo,
          ),
          const SizedBox(height: 12),
          DeclinedDetailsCard(app: app),
          const SizedBox(height: 16),
          AppealButton(
            referenceNo: app.referenceNo,
            label: 'File an Appeal',
            onPressed: () => _go(AppRoutes.appeal),
          ),
        ],
      PermitStatus.appealReview => [
          StatusSummaryCard(
            icon: Icons.schedule_rounded,
            title: 'Appeal Under Review',
            badgeText: 'UNDER RE-EVALUATION',
            tone: BadgeTone.gold,
            message:
                'The Security Office is checking your corrected documents.',
            reference: app.referenceNo,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Track Appeal',
            showArrow: true,
            onPressed: () => _go(AppRoutes.applicationStatus),
          ),
        ],
      PermitStatus.approved => [
          StatusSummaryCard(
            icon: Icons.verified_outlined,
            title: 'Permit Approved',
            badgeText: 'APPROVED',
            tone: BadgeTone.green,
            message:
                'Permit ${app.permitNo}. Your sticker is being prepared. We will notify you when it is ready.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'View Permit',
            showArrow: true,
            onPressed: () => _go(AppRoutes.permitDetails),
          ),
        ],
      PermitStatus.stickerReady => [
          const PickupBanner(),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'View Pickup Details',
            showArrow: true,
            onPressed: () => _go(AppRoutes.stickerPickup),
          ),
        ],
      PermitStatus.active => [
          StatusSummaryCard(
            icon: Icons.check_circle_outline,
            title: 'Permit Active',
            badgeText: 'ACTIVE',
            tone: BadgeTone.green,
            message:
                'Permit ${app.permitNo} for ${app.plate}. Valid until ${app.validUntil}.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'View Permit',
            showArrow: true,
            onPressed: () => _go(AppRoutes.permitDetails),
          ),
        ],
      PermitStatus.expiringSoon => [
          StatusSummaryCard(
            icon: Icons.notification_important_outlined,
            title: 'Permit Expiring Soon',
            badgeText: 'EXPIRING',
            tone: BadgeTone.gold,
            message:
                'Your permit expires on ${app.validUntil}. Renew it to keep parking on campus.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Renew Permit',
            showArrow: true,
            onPressed: () => _go(AppRoutes.renewal),
          ),
        ],
      PermitStatus.expired => [
          StatusSummaryCard(
            icon: Icons.event_busy_outlined,
            title: 'Permit Expired',
            badgeText: 'EXPIRED',
            tone: BadgeTone.red,
            message:
                'Your permit expired on ${app.validUntil}. Renew it to park on campus again.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Renew Permit',
            showArrow: true,
            onPressed: () => _go(AppRoutes.renewal),
          ),
        ],
    };
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