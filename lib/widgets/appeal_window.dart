import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';
import '../core/supabase_config.dart';
import 'app_buttons.dart';

/// An applicant can appeal a declined application once, within this many days.
const int kAppealDays = 7;

class AppealWindowState {
  const AppealWindowState({required this.daysLeft, required this.appealUsed});

  /// Days left to appeal. 0 means the window has ended.
  final int daysLeft;

  /// True when an appeal was already filed (and then declined again).
  final bool appealUsed;

  bool get canAppeal => !appealUsed && daysLeft > 0;
}

const AppealWindowState _open =
    AppealWindowState(daysLeft: kAppealDays, appealUsed: false);

/// Reads when the application was declined and whether an appeal was filed.
Future<AppealWindowState> loadAppealWindow(String referenceNo) async {
  if (!kSupabaseReady || referenceNo.isEmpty || referenceNo == '-') return _open;
  try {
    final row = await Supabase.instance.client
        .from('applications')
        .select('declined_at, appeals(id)')
        .eq('reference_no', referenceNo)
        .maybeSingle();
    if (row == null) return _open;
    final appeals = row['appeals'];
    final used = appeals is List ? appeals.isNotEmpty : appeals is Map;
    final declined = DateTime.tryParse((row['declined_at'] ?? '').toString());
    if (declined == null) return AppealWindowState(daysLeft: kAppealDays, appealUsed: used);
    final left = declined.toLocal().add(const Duration(days: kAppealDays)).difference(DateTime.now());
    final days = left.isNegative ? 0 : (left.inMinutes / (24 * 60)).ceil();
    return AppealWindowState(daysLeft: days, appealUsed: used);
  } catch (_) {
    // If it cannot be checked, the database still blocks a late or second appeal.
    return _open;
  }
}

Widget _notice({
  required bool red,
  required IconData icon,
  required String bold,
  required String rest,
}) {
  final fg = red ? AppColors.error : AppColors.goldDark;
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: red ? AppColors.errorLight : AppColors.goldLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: red ? AppColors.error : AppColors.gold),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 12.5, height: 1.4, color: fg),
              children: [
                TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(text: rest),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The yellow or red box under "What needs to be fixed".
class AppealWindowNotice extends StatefulWidget {
  const AppealWindowNotice({super.key, required this.referenceNo});

  final String referenceNo;

  @override
  State<AppealWindowNotice> createState() => _AppealWindowNoticeState();
}

class _AppealWindowNoticeState extends State<AppealWindowNotice> {
  AppealWindowState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AppealWindowNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceNo != widget.referenceNo) _load();
  }

  Future<void> _load() async {
    final s = await loadAppealWindow(widget.referenceNo);
    if (mounted) setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null) {
      return _notice(red: false, icon: Icons.timer_outlined, bold: 'Checking the appeal window...', rest: '');
    }
    if (s.appealUsed) {
      return _notice(
        red: true,
        icon: Icons.gavel_outlined,
        bold: 'Final decision.',
        rest: ' Your appeal was already reviewed. Please visit the Campus Security Office for help.',
      );
    }
    if (s.daysLeft <= 0) {
      return _notice(
        red: true,
        icon: Icons.event_busy_outlined,
        bold: 'The $kAppealDays-day appeal window has ended.',
        rest: ' Please visit the Campus Security Office for help.',
      );
    }
    final days = s.daysLeft == 1 ? '1 day' : '${s.daysLeft} days';
    return _notice(
      red: false,
      icon: Icons.timer_outlined,
      bold: 'Appeal window active: $days remaining',
      rest: ' to file an appeal or resubmit documents.',
    );
  }
}

/// The "File an Appeal" button. It is hidden when an appeal is no longer allowed.
class AppealButton extends StatefulWidget {
  const AppealButton({
    super.key,
    required this.referenceNo,
    required this.label,
    required this.onPressed,
  });

  final String referenceNo;
  final String label;
  final VoidCallback onPressed;

  @override
  State<AppealButton> createState() => _AppealButtonState();
}

class _AppealButtonState extends State<AppealButton> {
  AppealWindowState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AppealButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.referenceNo != widget.referenceNo) _load();
  }

  Future<void> _load() async {
    final s = await loadAppealWindow(widget.referenceNo);
    if (mounted) setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (s == null) {
      return PrimaryButton(label: widget.label, isLoading: true, onPressed: () {});
    }
    if (!s.canAppeal) return const SizedBox.shrink();
    return PrimaryButton(label: widget.label, showArrow: true, onPressed: widget.onPressed);
  }
}