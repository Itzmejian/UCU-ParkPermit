import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/constants.dart';
import '../../core/signup_info.dart';
import '../../models/network_store.dart';
import '../../models/profile_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/resend_button.dart';
import '../../widgets/security_footer.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  String get _email {
    final arg = ModalRoute.of(context)?.settings.arguments;
    return arg is SignupInfo ? arg.email : ProfileStore.instance.email;
  }

  Future<void> _verify() async {
    if (_loading) return;
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
    final result = await AuthService.verifySignupCode(email: _email, code: code);
    if (!mounted) return;
    if (!result.ok) {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Incorrect or expired code. Please try again.';
      });
      _codeCtrl.clear();
      return;
    }
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.completeProfile,
      arguments: SignupInfo(email: _email, role: ProfileStore.instance.role),
    );
  }

  Future<void> _resend() async {
    if (!NetworkStore.instance.ensureOnline(context)) return;
    final email = _email;
    final result = await AuthService.resendSignupCode(email);
    if (!mounted) return;
    _codeCtrl.clear();
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.ok ? 'A new code was sent to $email' : (result.error ?? 'Could not send a new code.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _email;

    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconBadge(icon: Icons.mark_email_unread_outlined),
              ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to\n'),
                    TextSpan(
                      text: email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              OtpInput(
                controller: _codeCtrl,
                length: kOtpLength,
                hasError: _error != null,
                enabled: !_loading,
                onCompleted: (_) => _verify(),
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
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify',
                showArrow: true,
                isLoading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 8),
              Center(
                child: ResendButton(
                  label: 'Resend code',
                  cooldownSeconds: kOtpResendSeconds,
                  onResend: _resend,
                ),
              ),
              const Text(
                'The code is valid for 1 hour. Check your spam folder if it does not arrive.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
              ),
              if (kShowDevOtpHint && !AuthService.live) ...[
                const SizedBox(height: 16),
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
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.register),
                child: const Text(
                  'Use a different email',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SecurityFooter(),
    );
  }
}