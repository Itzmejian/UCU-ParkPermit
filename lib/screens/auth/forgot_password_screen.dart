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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _resetForm = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  int _step = 0; // 0 = email, 1 = code and new password, 2 = done
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    });
  }

  Future<void> _resend() async {
    if (!NetworkStore.instance.ensureOnline(context)) return;
    final r = await AuthService.sendResetCode(_emailCtrl.text.trim());
    if (!mounted) return;
    _codeCtrl.clear();
    _snack(r.ok ? 'A new code was sent.' : (r.error ?? 'Could not send a new code.'));
  }

  Future<void> _reset() async {
    final code = _codeCtrl.text.trim();
    if (code.length != kOtpLength) {
      setState(() => _error = 'Enter the $kOtpLength-digit code.');
      return;
    }
    if (!_resetForm.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await AuthService.resetPasswordWithCode(
      email: _emailCtrl.text.trim(),
      code: code,
      newPassword: _passCtrl.text,
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

  Widget _stepEmail() {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: IconBadge(icon: Icons.lock_reset_rounded)),
          const SizedBox(height: 20),
          const Text(
            'Forgot your password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your email and we will send you a 6-digit code to set a new password.',
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

  Widget _stepReset() {
    return Form(
      key: _resetForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: IconBadge(icon: Icons.mark_email_unread_outlined)),
          const SizedBox(height: 20),
          const Text(
            'Enter the code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
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
          const SizedBox(height: 20),
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
            onSubmitted: (_) => _reset(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Reset Password',
            showArrow: true,
            isLoading: _loading,
            onPressed: _reset,
          ),
          const SizedBox(height: 4),
          Center(
            child: ResendButton(
              label: 'Resend code',
              cooldownSeconds: kOtpResendSeconds,
              onResend: _resend,
            ),
          ),
          if (kShowDevOtpHint && !AuthService.live)
            Container(
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
            onPressed: () => setState(() {
              _step = 0;
              _error = null;
              _codeCtrl.clear();
            }),
            child: const Text(
              'Use a different email',
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
        const Center(
          child: IconBadge(
            icon: Icons.check_rounded,
            background: AppColors.successLight,
            foreground: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Password updated',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
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
      1 => _stepReset(),
      _ => _stepDone(),
    };
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: body,
        ),
      ),
      bottomNavigationBar: const SecurityFooter(),
    );
  }
}