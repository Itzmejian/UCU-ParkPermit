import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';

/// Guard forgot password: email, then the 6-digit code, then a new password.
///
/// With [activate], it is the first-time setup for a guard the Security
/// Office invited: the invite email already has the code, so step 1 does
/// not send another one.
Future<void> showGuardForgotDialog(BuildContext context, {String email = '', bool activate = false}) async {
  final done = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GuardForgotDialog(email: email, activate: activate),
  );
  if (done == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(activate
            ? 'Account activated. Log in with your email and new password.'
            : 'Password changed. Log in with your new password.'),
      ),
    );
  }
}

class _GuardForgotDialog extends StatefulWidget {
  const _GuardForgotDialog({required this.email, this.activate = false});

  final String email;
  final bool activate;

  @override
  State<_GuardForgotDialog> createState() => _GuardForgotDialogState();
}

class _GuardForgotDialogState extends State<_GuardForgotDialog> {
  late final TextEditingController _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  int _step = 0; // 0 = email, 1 = code, 2 = new password
  bool _busy = false;
  bool _hide = true;
  String? _error;

  SupabaseClient get _c => Supabase.instance.client;

  @override
  void dispose() {
    for (final c in [_email, _code, _pw, _pw2]) {
      c.dispose();
    }
    super.dispose();
  }

  String _msg(Object e) {
    final m = (e is AuthException ? e.message : e.toString()).toLowerCase();
    if (m.contains('rate') || m.contains('seconds') || m.contains('security purposes')) {
      return 'Please wait a minute before trying again.';
    }
    if (m.contains('expired') || m.contains('invalid') || m.contains('token')) {
      return 'The code is wrong or expired.';
    }
    if (m.contains('same')) return 'Use a password different from your old one.';
    if (m.contains('weak') || m.contains('at least')) return 'Use at least 8 characters.';
    if (m.contains('socket') || m.contains('failed host') || m.contains('network')) {
      return 'No internet connection. Please try again.';
    }
    return e is AuthException ? e.message : 'Something went wrong. Please try again.';
  }

  Future<bool> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
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

  Future<void> _send() async {
    final e = _email.text.trim();
    if (!e.contains('@')) {
      setState(() => _error = 'Enter your guard email.');
      return;
    }
    _code.clear();
    if (await _run(() => _c.auth.resetPasswordForEmail(e)) && mounted) {
      setState(() => _step = 1);
    }
  }

  /// Activation: the code is already in the invite email, so just go on.
  void _next() {
    if (!_email.text.trim().contains('@')) {
      setState(() => _error = 'Enter the email the Security Office used for your invite.');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    final ok = await _run(() async {
      await _c.auth.verifyOTP(
        type: OtpType.recovery,
        email: _email.text.trim(),
        token: _code.text.trim(),
      );
    });
    if (ok && mounted) setState(() => _step = 2);
  }

  Future<void> _save() async {
    if (_pw.text.length < 8) {
      setState(() => _error = 'The new password needs at least 8 characters.');
      return;
    }
    if (_pw.text != _pw2.text) {
      setState(() => _error = 'The new passwords do not match.');
      return;
    }
    final ok = await _run(() async {
      await _c.auth.updateUser(UserAttributes(password: _pw.text));
      await _c.auth.signOut();
    });
    if (ok && mounted) Navigator.pop(context, true);
  }

  Future<void> _cancel() async {
    // After the code is verified the guard is logged in, so log out again.
    if (_step == 2) {
      try {
        await _c.auth.signOut();
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activate;
    final title = switch (_step) {
      0 => act ? 'Activate guard account' : 'Forgot password',
      1 => 'Enter the code',
      _ => act ? 'Create your password' : 'Create a new password',
    };
    final text = switch (_step) {
      0 => act
          ? 'Enter the email (Gmail) the Security Office used to invite you.'
          : 'Enter your guard email. We will send a 6-digit code to reset your password.',
      1 => act
          ? 'Enter the 6-digit code from your invite email sent to ${_email.text.trim()}. '
              'The email may say "Reset password". Check your spam folder too. '
              'If it expired, tap Resend.'
          : 'We sent a 6-digit code to ${_email.text.trim()}. Check your inbox and spam folder.',
      _ => act
          ? 'Your code is verified. Choose the password you will use to log in as a guard.'
          : 'Your code is verified. Choose a new password for your guard account.',
    };
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP ${_step + 1} OF 3',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 14),
            if (_step == 0)
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
              )
            else if (_step == 1)
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
              )
            else ...[
              TextField(
                controller: _pw,
                autofocus: true,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pw2,
                obscureText: _hide,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : _cancel, child: const Text('Cancel')),
        if (_step == 1) TextButton(onPressed: _busy ? null : _send, child: const Text('Resend')),
        FilledButton(
          onPressed: _busy
              ? null
              : switch (_step) {
                  0 => act ? _next : _send,
                  1 => _verify,
                  _ => _save,
                },
          child: Text(switch (_step) {
            0 => act ? 'Next' : 'Send Code',
            1 => 'Verify Code',
            _ => 'Save',
          }),
        ),
      ],
    );
  }
}
