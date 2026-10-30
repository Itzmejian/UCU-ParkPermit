import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class GuardResultScreen extends StatefulWidget {
  const GuardResultScreen({super.key, required this.result});

  final Map<String, dynamic> result;

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

  Widget _photoBox() {
    const size = Size(110, 140);
    Widget placeholder(String text) => Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 40, color: AppColors.textHint),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
        );
    if (_photoLoading) {
      return SizedBox(
        width: size.width,
        height: size.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_photo == null) return placeholder('No photo');
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        _photo!,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder('No photo'),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
    final (String title, String message, Color fg, Color bg, IconData icon) = switch (res) {
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
    final found = res != 'not_found';
    final isEmployee = _s('role') == 'employee';

    return Scaffold(
      appBar: AppBar(title: const Text('Verification', style: TextStyle(fontWeight: FontWeight.w800))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: fg, width: 2),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 52, color: fg),
                  const SizedBox(height: 8),
                  Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: fg)),
                  const SizedBox(height: 6),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textDark)),
                ],
              ),
            ),
            if (found) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('PLATE NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.textHint)),
                    const SizedBox(height: 4),
                    Text(
                      _s('plate'),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check that it matches the vehicle in front of you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _photoBox(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_s('name'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(isEmployee ? 'Employee' : 'Student', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Text(
                            _s('id_number'),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                          ),
                          const SizedBox(height: 4),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _row('Vehicle', _s('make_model')),
                    _row('Color', _s('color')),
                    _row('Type', _s('vehicle_type') == 'motorcycle' ? 'Motorcycle' : '4-Wheel Vehicle'),
                    _row('Permit no.', _s('permit_no')),
                    _row('Parking zone', _s('zone')),
                    _row('Valid until', _date(_s('valid_until'))),
                    _row('Sticker', _s('sticker_status')),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Scan Next',
              showArrow: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}