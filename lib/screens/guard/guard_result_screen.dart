import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Title, message, color, light color and icon for each result.
(String, String, Color, Color, IconData) guardResultStyle(String res) {
  return switch (res) {
    'valid' => (
        'VALID PERMIT',
        'This vehicle is registered and the permit is active.',
        AppColors.success,
        AppColors.successLight,
        Icons.verified_rounded,
      ),
    'not_claimed' => (
        'STICKER NOT CLAIMED',
        'The permit exists, but its sticker was not released yet. Ask the driver to go to the Security Office.',
        AppColors.goldDark,
        AppColors.goldLight,
        Icons.info_outline_rounded,
      ),
    'expired' => (
        'PERMIT EXPIRED',
        'This permit is no longer valid. Direct the driver to the visitor parking bays.',
        AppColors.error,
        AppColors.errorLight,
        Icons.event_busy_rounded,
      ),
    'inactive' => (
        'VEHICLE REMOVED',
        'This vehicle was removed from the system. The sticker is not valid.',
        AppColors.error,
        AppColors.errorLight,
        Icons.block_rounded,
      ),
    _ => (
        'NOT FOUND',
        'No permit matches this sticker or number. It may be fake, replaced or mistyped.',
        AppColors.error,
        AppColors.errorLight,
        Icons.gpp_bad_outlined,
      ),
  };
}

String guardTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

class GuardResultScreen extends StatefulWidget {
  const GuardResultScreen({super.key, required this.result, this.checkedAt});

  final Map<String, dynamic> result;
  final DateTime? checkedAt;

  @override
  State<GuardResultScreen> createState() => _GuardResultScreenState();
}

class _GuardResultScreenState extends State<GuardResultScreen> {
  String? _photo;
  bool _photoLoading = true;

  @override
  void initState() {
    super.initState();
    GuardService.photoUrl(widget.result['photo_path']?.toString()).then((u) {
      if (!mounted) return;
      setState(() {
        _photo = u;
        _photoLoading = false;
      });
    });
  }

  String _s(String key) => (widget.result[key] ?? '').toString();

  String _date(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso.isEmpty ? '-' : iso;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _photoBox() {
    Widget placeholder() => Container(
          width: 104,
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 40, color: AppColors.textHint),
              SizedBox(height: 4),
              Text('No photo', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        );
    if (_photoLoading) {
      return const SizedBox(width: 104, height: 132, child: Center(child: CircularProgressIndicator()));
    }
    if (_photo == null) return placeholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        _photo!,
        width: 104,
        height: 132,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder(),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textHint),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textHint)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = _s('result').isEmpty ? 'not_found' : _s('result');
    final (title, message, fg, _, icon) = guardResultStyle(res);
    final found = res != 'not_found';
    final isEmployee = _s('role') == 'employee';
    final checked = widget.checkedAt ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: fg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 26),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            'Checked at ${guardTime(checked)}',
                            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(icon, size: 52, color: fg),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (found) ...[
                  _card(
                    child: Column(
                      children: [
                        const Text(
                          'PLATE NUMBER',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.navy, width: 2.5),
                          ),
                          child: Text(
                            _s('plate'),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.navy),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check that it matches the vehicle in front of you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _photoBox(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isEmployee ? 'EMPLOYEE' : 'STUDENT',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _s('name'),
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _s('id_number'),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                              ),
                              const SizedBox(height: 2),
                              Text(_s('unit'), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 8),
                              const Text(
                                'Photo from the UCU ID they submitted.',
                                style: TextStyle(fontSize: 11, color: AppColors.textHint),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _card(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      children: [
                        _row(
                          _s('vehicle_type') == 'motorcycle' ? Icons.two_wheeler : Icons.directions_car_outlined,
                          'Vehicle',
                          _s('make_model'),
                        ),
                        _row(Icons.palette_outlined, 'Color', _s('color')),
                        _row(Icons.confirmation_number_outlined, 'Permit no.', _s('permit_no')),
                        _row(Icons.local_parking, 'Zone', _s('zone')),
                        _row(Icons.event_outlined, 'Valid until', _date(_s('valid_until'))),
                        _row(Icons.sell_outlined, 'Sticker', _s('sticker_status')),
                      ],
                    ),
                  ),
                ] else
                  _card(
                    child: const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.goldDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Try typing the permit number or plate number. If it is still not found, ask the driver to visit the Security Office.',
                            style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Scan Next',
                  showArrow: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}