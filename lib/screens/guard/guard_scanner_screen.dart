import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../services/guard_service.dart';
import 'guard_result_screen.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  final TextEditingController _manual = TextEditingController();
  bool _busy = false;
  String _guardName = '';

  @override
  void initState() {
    super.initState();
    GuardService.guardName().then((n) {
      if (mounted) setState(() => _guardName = n);
    });
  }

  @override
  void dispose() {
    _scanner.dispose();
    _manual.dispose();
    super.dispose();
  }

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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GuardResultScreen(result: result!)),
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
        title: const Text('Log out?'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sticker Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(
              _guardName.isEmpty ? 'Security guard' : _guardName,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Log out', icon: const Icon(Icons.logout), onPressed: _logout),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(controller: _scanner, onDetect: _onDetect),
                      Center(
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      if (_busy)
                        Container(
                          color: Colors.black45,
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Point the camera at the QR code on the parking sticker.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _manual,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _check,
                      decoration: const InputDecoration(
                        hintText: 'Or type permit no. or plate',
                        prefixIcon: Icon(Icons.keyboard_outlined),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _busy ? null : () => _check(_manual.text),
                    child: const Text('Check'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}