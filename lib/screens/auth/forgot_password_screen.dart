import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/network_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/resend_button.dart';
import '../../widgets/security_footer.dart';

/// Forgot Password in four screens:
/// 0 email, 1 code, 2 new password (only after the code is right), 3 done.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _passForm = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  int _step = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    // Leaving after the code was checked but before saving: sign out again.
    if (_step == 2) AuthService.cancelPasswordReset();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Back from the code or password screen goes to the email screen.
  void _backToEmail() {
    if (_step == 2) AuthService.cancelPasswordReset();
    setState(() {
      _step = 0;
      _error = null;
      _codeCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  Future<void> _sendCode() async {
    if (!_emailForm.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    final r = await AuthService.sendResetCode(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (!r.ok) {
      _snack(r.error ?? 'Could not send the code. Please try again.');
      return;
    }
    setState(() {
      _step = 1;
      _error = null;
      _codeCtrl.clear();
    });
  }

  Future<void> _resend() async {
    if (!NetworkStore.instance.ensureOnline(context)) return;
    final r = await AuthService.sendResetCode(_emailCtrl.text.trim());
    if (!mounted) return;
    _codeCtrl.clear();
    setState(() => _error = null);
    _snack(r.ok ? 'A new code was sent.' : (r.error ?? 'Could not send a new code.'));
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.length != kOtpLength) {
      setState(() => _error = 'Enter the $kOtpLength-digit code.');
      return;
    }
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await AuthService.verifyResetCode(
      email: _emailCtrl.text.trim(),
      code: code,
    );
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _loading = false;
        _error = r.error ?? 'Incorrect or expired code. Please try again.';
      });
      return;
    }
    setState(() {
      _loading = false;
      _step = 2;
    });
  }

  Future<void> _savePassword() async {
    if (!_passForm.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    final r = await AuthService.setNewPassword(_passCtrl.text);
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _loading = false);
      _snack(r.error ?? 'Could not save your new password. Please try again.');
      return;
    }
    setState(() {
      _loading = false;
      _step = 3;
    });
  }

  Widget _stepLabel(int n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        'STEP $n OF 3',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    );
  }

  Widget _stepEmail() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepLabel(1),
          const Center(child: IconBadge(icon: Icons.lock_reset_rounded)),
          const SizedBox(height: 20),
          _title('Forgot your password?'),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we will send you a 6-digit code.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Email',
            hint: 'e.g., juan@example.com',
            icon: Icons.mail_outline,
            controller: _emailCtrl,
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Send reset code',
            showArrow: true,
            isLoading: _loading,
            onPressed: _sendCode,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text(
              'Back to Log In',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepLabel(2),
        const Center(child: IconBadge(icon: Icons.mark_email_unread_outlined)),
        const SizedBox(height: 20),
        _title('Enter the code'),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted),
            children: [
              const TextSpan(text: 'If an account exists for\n'),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(text: '\nwe sent a 6-digit code.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        OtpInput(
          controller: _codeCtrl,
          length: kOtpLength,
          hasError: _error != null,
          enabled: !_loading,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
            ),
          ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Verify Code',
          showArrow: true,
          isLoading: _loading,
          onPressed: _verifyCode,
        ),
        const SizedBox(height: 4),
        Center(
          child: ResendButton(
            label: 'Resend code',
            cooldownSeconds: kOtpResendSeconds,
            onResend: _resend,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'The code is valid for 1 hour. Check your spam folder if it does not arrive.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
          ),
        ),
        if (kShowDevOtpHint && !AuthService.live)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold),
            ),
            child: const Text(
              'Prototype mode: no email is sent. Use code $kDevOtp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.goldDark),
            ),
          ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _backToEmail,
          child: const Text(
            'Use a different email',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
        ),
      ],
    );
  }

  Widget _stepPassword() {
    return Form(
      key: _passForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepLabel(3),
          const Center(child: IconBadge(icon: Icons.password_rounded)),
          const SizedBox(height: 20),
          _title('Create a new password'),
          const SizedBox(height: 8),
          const Text(
            'Your code is verified. Choose a new password for your account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          AppTextField(
            label: 'New Password',
            hint: 'Create a new password',
            icon: Icons.lock_outline,
            controller: _passCtrl,
            isRequired: true,
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Use at least 8 characters.',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Confirm New Password',
            hint: 'Re-enter the new password',
            icon: Icons.lock_outline,
            controller: _confirmCtrl,
            isRequired: true,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.confirmPassword(v, _passCtrl.text),
            onSubmitted: (_) => _savePassword(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Save New Password',
            showArrow: true,
            isLoading: _loading,
            onPressed: _savePassword,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _loading ? null : _backToEmail,
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Center(
          child: IconBadge(
            icon: Icons.check_rounded,
            background: AppColors.successLight,
            foreground: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        _title('Password updated'),
        const SizedBox(height: 8),
        const Text(
          'You can now log in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Back to Log In',
          showArrow: true,
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget body = switch (_step) {
      0 => _stepEmail(),
      1 => _stepCode(),
      2 => _stepPassword(),
      _ => _stepDone(),
    };
    final canLeave = _step == 0 || _step == 3;
    return PopScope(
      canPop: canLeave,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_loading) _backToEmail();
      },
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: _step != 3),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: body,
          ),
        ),
        bottomNavigationBar: const SecurityFooter(),
      ),
    );
  }
}