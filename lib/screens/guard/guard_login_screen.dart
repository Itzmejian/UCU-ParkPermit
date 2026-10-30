import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';

class GuardLoginScreen extends StatefulWidget {
  const GuardLoginScreen({super.key});

  @override
  State<GuardLoginScreen> createState() => _GuardLoginScreenState();
}

class _GuardLoginScreenState extends State<GuardLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await GuardService.signIn(email, _password.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, kGuardRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: AppColors.inputFill, shape: BoxShape.circle),
                  child: const Icon(Icons.shield_outlined, size: 38, color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Guard Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'For campus security guards only. Accounts are given by the Campus Security Office.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 26),
              AppTextField(
                label: 'Email',
                hint: 'Your guard account email',
                icon: Icons.mail_outline,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Password',
                hint: 'Your password',
                icon: Icons.lock_outline,
                controller: _password,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Log In as Guard',
                showArrow: true,
                isLoading: _loading,
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}