import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/otp_input.dart';

/// A guard creates their account after the Security Office invites them:
/// 1 email, 2 the 6-digit code from the invite email, 3 check the details
/// the admin entered, 4 create a password.
///
/// Pops with the guard's email when the account is ready.
class GuardCreateAccountScreen extends StatefulWidget {
  const GuardCreateAccountScreen({super.key, this.email = ''});

  final String email;

  @override
  State<GuardCreateAccountScreen> createState() => _GuardCreateAccountScreenState();
}

class _GuardCreateAccountScreenState extends State<GuardCreateAccountScreen> {
  late final TextEditingController _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  int _step = 0; // 0 email, 1 code, 2 details, 3 password
  bool _busy = false;
  String? _error;
  String? _info;
  Map<String, dynamic> _profile = {};

  SupabaseClient get _c => Supabase.instance.client;

  static const _titles = ['Your email', 'Enter the code', 'Check your details', 'Create your password'];

  @override
  void dispose() {
    for (final c in [_email, _code, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  String _msg(Object e) {
    final raw = e is AuthException ? e.message : (e is PostgrestException ? e.message : e.toString());
    final m = raw.toLowerCase();
    if (raw.contains('NOT_GUARD')) {
      return 'This email has no guard invite. Ask the Security Office to invite you first.';
    }
    if (m.contains('rate') || m.contains('seconds') || m.contains('security purposes')) {
      return 'Please wait a minute before trying again.';
    }
    if (m.contains('expired') || m.contains('invalid') || m.contains('token')) {
      return 'The code is wrong or expired. Check the email again or send a new code.';
    }
    if (m.contains('same')) return 'Use a different password.';
    if (m.contains('weak') || m.contains('at least')) return 'Use at least 8 characters.';
    if (m.contains('socket') || m.contains('failed host') || m.contains('network')) {
      return 'No internet connection. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<bool> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
      if (mounted) setState(() => _busy = false);
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _msg(e);
        });
      }
      return false;
    }
  }

  Future<void> _signOutQuietly() async {
    try {
      await _c.auth.signOut();
    } catch (_) {}
  }

  // ---------- step 1: email ----------

  void _next() {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = 'Enter the email the Security Office used for your invite.');
      return;
    }
    _code.clear();
    setState(() {
      _error = null;
      _info = null;
      _step = 1;
    });
  }

  Future<void> _sendNewCode() async {
    final ok = await _run(() => _c.auth.resetPasswordForEmail(_email.text.trim().toLowerCase()));
    if (ok && mounted) {
      _code.clear();
      setState(() {
        _info = 'A new 6-digit code was sent to ${_email.text.trim()}.';
        _step = 1;
      });
    }
  }

  // ---------- step 2: code ----------

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    String? stop;
    final ok = await _run(() async {
      await _c.auth.verifyOTP(type: OtpType.recovery, email: _email.text.trim().toLowerCase(), token: code);
      try {
        _profile = await GuardService.myProfile();
      } catch (e) {
        await _signOutQuietly();
        rethrow;
      }
      if (_profile['active'] != true) {
        await _signOutQuietly();
        stop = 'Your guard account is deactivated. Contact the Security Office.';
      }
    });
    if (!mounted || !ok) return;
    if (stop != null) {
      setState(() => _error = stop);
      return;
    }
    setState(() => _step = 2);
  }

  // ---------- step 3: details ----------

  Future<void> _wrongDetails() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Details not correct?'),
        content: const Text(
          'Please tell the Campus Security Office what is wrong. They will fix your details '
          'on the admin website and send you a new code. Then come back here and tap '
          '"Create guard account" again.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    await _signOutQuietly();
    if (mounted) Navigator.pop(context);
  }

  // ---------- step 4: password ----------

  Future<void> _save() async {
    if (_pw.text.length < 8) {
      setState(() => _error = 'Your password needs at least 8 characters.');
      return;
    }
    if (_pw.text != _pw2.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    final ok = await _run(() async {
      await _c.auth.updateUser(UserAttributes(password: _pw.text));
      await GuardService.markActivated();
      await _signOutQuietly();
    });
    if (ok && mounted) Navigator.pop(context, _email.text.trim().toLowerCase());
  }

  Future<void> _leave() async {
    if (_step >= 2) await _signOutQuietly();
    if (mounted) Navigator.pop(context);
  }

  void _back() {
    if (_busy) return;
    if (_step == 1) {
      setState(() {
        _step = 0;
        _error = null;
        _info = null;
      });
    } else {
      _leave();
    }
  }

  // ---------- UI ----------

  Widget _stepBar() {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= _step ? AppColors.gold : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
      ],
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _birthday(dynamic v) {
    final d = DateTime.tryParse((v ?? '').toString());
    if (d == null) return '';
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _address() => [_profile['address'], _profile['city'], _profile['province']]
      .map((e) => (e ?? '').toString().trim())
      .where((e) => e.isNotEmpty)
      .join(', ');

  Widget _detailRow(IconData icon, String label, dynamic value) {
    final v = (value ?? '').toString().trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(
                  v.isEmpty ? 'Not set' : v,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: v.isEmpty ? AppColors.textHint : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email (Gmail) the Security Office used to invite you. '
              'Your invite email has a 6-digit code.',
              style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email',
              hint: 'yourname@gmail.com',
              icon: Icons.mail_outline,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Next', showArrow: true, isLoading: _busy, onPressed: _next),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        if (!_email.text.contains('@')) {
                          setState(() => _error = 'Enter your email first.');
                          return;
                        }
                        _sendNewCode();
                      },
                child: const Text('No code or it expired? Send a new code'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-digit code sent to ${_email.text.trim()}. '
              'The email may say "Reset password". Check your Spam folder too.',
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
            ),
            const SizedBox(height: 22),
            OtpInput(
              controller: _code,
              hasError: _error != null,
              enabled: !_busy,
              onCompleted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Verify code', isLoading: _busy, onPressed: _verify),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _sendNewCode,
                child: const Text('Send a new code'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'These are the details the Campus Security Office entered for you. '
              'Check that everything is correct before you continue.',
              style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _detailRow(Icons.person_outline, 'Full name', _profile['full_name']),
                  _detailRow(Icons.mail_outline, 'Email', _profile['email']),
                  _detailRow(Icons.badge_outlined, 'Guard ID', _profile['id_no']),
                  _detailRow(Icons.phone_outlined, 'Mobile number', _profile['phone']),
                  _detailRow(Icons.cake_outlined, 'Birthday', _birthday(_profile['birthdate'])),
                  _detailRow(Icons.wc_outlined, 'Sex', _profile['sex']),
                  _detailRow(Icons.home_outlined, 'Home address', _address()),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Yes, these are correct',
              showArrow: true,
              onPressed: () => setState(() {
                _error = null;
                _step = 3;
              }),
            ),
            const SizedBox(height: 10),
            SecondaryButton(label: 'Something is wrong', onPressed: _wrongDetails),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Last step, ${(_profile['full_name'] ?? '').toString().split(' ').first}. '
              'Create the password you will use to log in as a guard.',
              style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline,
              controller: _pw,
              isPassword: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Confirm password',
              hint: 'Type it again',
              icon: Icons.lock_outline,
              controller: _pw2,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'Create account', isLoading: _busy, onPressed: _save),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back),
          title: const Text('Create guard account', style: TextStyle(fontWeight: FontWeight.w800)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(46),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STEP ${_step + 1} OF 4',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _stepBar(),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _titles[_step],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                const SizedBox(height: 8),
                if (_info != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_info!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  ),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                _body(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
