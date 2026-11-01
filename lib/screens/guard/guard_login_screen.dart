import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import 'guard_help_screen.dart';

const Color _navyDark = Color(0xFF0F2552);

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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, _navyDark],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.shield, size: 44, color: AppColors.navy),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Guard Portal',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'URDANETA CITY UNIVERSITY SECURITY OFFICE',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Log in to scan stickers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'For campus security guards only. Accounts are given by the Campus Security Office.',
                    style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    label: 'Email',
                    hint: 'Email',
                    icon: Icons.mail_outline,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    controller: _password,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Log In as Guard',
                    showArrow: true,
                    isLoading: _loading,
                    onPressed: _login,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GuardHelpScreen(loggedIn: false)),
                      ),
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('Need help? Guard FAQ'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, size: 18, color: AppColors.navy),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Every sticker check is recorded with your account.',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}