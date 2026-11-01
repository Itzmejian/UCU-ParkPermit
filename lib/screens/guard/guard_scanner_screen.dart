import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/permissions.dart';
import '../../services/guard_service.dart';
import 'guard_help_screen.dart';
import 'guard_result_screen.dart';

const Color _navyDark = Color(0xFF0F2552);

class _ScanRecord {
  const _ScanRecord(this.result, this.time);

  final Map<String, dynamic> result;
  final DateTime time;
}

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _manual = TextEditingController();
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _busy = false;
  bool? _cameraOk;
  String _guardName = '';
  final List<_ScanRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _checkCamera();
    GuardService.guardName().then((n) {
      if (mounted) setState(() => _guardName = n);
    });
  }

  @override
  void dispose() {
    _line.dispose();
    _scanner.dispose();
    _manual.dispose();
    super.dispose();
  }

  Future<void> _checkCamera() async {
    final ok = await ensureCameraPermission(context);
    if (mounted) setState(() => _cameraOk = ok);
  }

  int get _validCount => _history.where((h) => h.result['result'] == 'valid').length;

  Future<void> _check(String code) async {
    final value = code.trim();
    if (_busy || value.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    Map<String, dynamic>? result;
    String? error;
    try {
      result = await GuardService.verify(value);
    } catch (e) {
      error = GuardService.friendly(e);
    }
    if (!mounted) return;
    if (error != null || result == null) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Please try again.')));
      return;
    }
    final record = _ScanRecord(result, DateTime.now());
    setState(() => _history.insert(0, record));
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuardResultScreen(result: record.result, checkedAt: record.time)),
    );
    if (!mounted) return;
    _manual.clear();
    setState(() => _busy = false);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_busy) return;
    for (final b in capture.barcodes) {
      final v = b.rawValue;
      if (v != null && v.isNotEmpty) {
        _check(v);
        return;
      }
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End your shift?'),
        content: const Text('You will need to log in again to scan stickers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true) return;
    await GuardService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.welcome, (route) => false);
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, _navyDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 8, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                    child: const Icon(Icons.shield, color: AppColors.navy),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _guardName.isEmpty ? 'Security guard' : _guardName,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.circle, size: 9, color: Color(0xFF4ADE80)),
                            SizedBox(width: 6),
                            Text('On duty', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Help',
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GuardHelpScreen()),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _stat('Checked', _history.length, Colors.white),
                  const SizedBox(width: 8),
                  _stat('Valid', _validCount, const Color(0xFF4ADE80)),
                  const SizedBox(width: 8),
                  _stat('Problems', _history.length - _validCount, const Color(0xFFFCA5A5)),
                  const SizedBox(width: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cameraBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_cameraOk == true)
              MobileScanner(controller: _scanner, onDetect: _onDetect)
            else
              Container(
                color: _navyDark,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 46, color: Colors.white70),
                    const SizedBox(height: 12),
                    Text(
                      _cameraOk == null
                          ? 'Starting the camera...'
                          : 'Camera access is needed to scan stickers. You can still type the permit number or plate below.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_cameraOk == false) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _checkCamera,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Allow camera'),
                      ),
                    ],
                  ],
                ),
              ),
            if (_cameraOk == true) ...[
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: CustomPaint(painter: _CornersPainter()),
                ),
              ),
              AnimatedBuilder(
                animation: _line,
                builder: (context, child) => Align(
                  alignment: Alignment(0, -0.62 + _line.value * 1.24),
                  child: Container(
                    width: 200,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0),
                          AppColors.gold,
                          AppColors.gold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Point at the QR code on the sticker',
                      style: TextStyle(fontSize: 12.5, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
            if (_busy)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _manualCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.keyboard_outlined, size: 20, color: AppColors.navy),
              SizedBox(width: 8),
              Text("Can't scan the QR?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Type the permit number or the plate number.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _check,
                  decoration: InputDecoration(
                    hintText: 'Permit no. or plate',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _busy ? null : () => _check(_manual.text),
                  child: const Text('Check'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THIS SHIFT',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.goldDark),
        ),
        const SizedBox(height: 8),
        for (final h in _history.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GuardResultScreen(result: h.result, checkedAt: h.time)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Builder(
                    builder: (context) {
                      final (title, _, fg, bg, icon) = guardResultStyle((h.result['result'] ?? 'not_found').toString());
                      final plate = (h.result['plate'] ?? '').toString();
                      return Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                            child: Icon(icon, color: fg, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plate.isEmpty ? 'Unknown sticker' : plate,
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                Text(title, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fg)),
                              ],
                            ),
                          ),
                          Text(guardTime(h.time), style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, color: AppColors.textHint),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _cameraBox(),
                const SizedBox(height: 14),
                _manualCard(),
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _historyList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold corners around the scan area.
class _CornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, l)..lineTo(0, 0)..lineTo(l, 0)
      ..moveTo(w - l, 0)..lineTo(w, 0)..lineTo(w, l)
      ..moveTo(w, h - l)..lineTo(w, h)..lineTo(w - l, h)
      ..moveTo(l, h)..lineTo(0, h)..lineTo(0, h - l);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}