import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/resend_button.dart';
import '../../widgets/security_footer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: Supabase resetPasswordForEmail goes here.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = true;
    });
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
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
            'Enter your email and we will send you a link to set a new password.',
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
            onSubmitted: (_) => _send(),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Send reset link',
            showArrow: true,
            isLoading: _loading,
            onPressed: _send,
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

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: IconBadge(
            icon: Icons.mark_email_read_outlined,
            background: AppColors.successLight,
            foreground: AppColors.success,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check your email',
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
              const TextSpan(text: 'We sent a password reset link to\n'),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const TextSpan(
                text: '\nCheck your spam folder if you do not see it.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: ResendButton(
            label: 'Resend link',
            onResend: () {
              // TODO: Supabase resetPasswordForEmail again.
            },
          ),
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Back to Log In',
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: _sent ? _buildSent() : _buildForm(),
        ),
      ),
      bottomNavigationBar: const SecurityFooter(),
    );
  }
}