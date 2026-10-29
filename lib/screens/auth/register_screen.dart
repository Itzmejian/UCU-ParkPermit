import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/network_store.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/signup_info.dart';
import '../../models/profile_store.dart';
import '../../core/validators.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/role_option.dart';
import '../../widgets/security_footer.dart';
import '../../widgets/ucu_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _role;
  bool _roleError = false;
  bool _accepted = false;
  bool _termsError = false;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() {
      _roleError = _role == null;
      _termsError = !_accepted;
    });
    if (!valid || _role == null || !_accepted) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    // TODO: Supabase sign up goes here (save the role with the account).
    ProfileStore.instance.setAccount(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      role: _role!,
    );
    final result = await AuthService.signUp(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _role!,
    );
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not create the account.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.verifyEmail,
      arguments: SignupInfo(email: _emailCtrl.text.trim(), role: _role!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create your account',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Register to manage your vehicle parking permit at UCU.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    UcuLogo(size: 56),
                  ],
                ),
                const SizedBox(height: 24),
                const Text.rich(
                  TextSpan(
                    text: 'I am a',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  
                  children: [
                    Expanded(
                      child: RoleOption(
                        label: kRoleStudent,
                        subtitle: 'Enrolled student',
                        icon: Icons.school_outlined,
                        selected: _role == kRoleStudent,
                        onTap: () => setState(() {
                          _role = kRoleStudent;
                          _roleError = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RoleOption(
                        label: kRoleEmployee,
                        subtitle: 'Instructor or staff',
                        icon: Icons.work_outline,
                        selected: _role == kRoleEmployee,
                        onTap: () => setState(() {
                          _role = kRoleEmployee;
                          _roleError = false;
                        }),
                      ),
                    ),
                  ],
                ),
                if (_roleError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Please choose if you are a Student or an Employee.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Full Name',
                  hint: 'e.g., Juan Dela Cruz',
                  icon: Icons.person_outline,
                  controller: _nameCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  hint: 'e.g., juan@example.com',
                  icon: Icons.mail_outline,
                  controller: _emailCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Create a password',
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
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_outline,
                  controller: _confirmCtrl,
                  isRequired: true,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      Validators.confirmPassword(v, _passCtrl.text),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _accepted,
                        activeColor: AppColors.navy,
                        onChanged: (v) => setState(() {
                          _accepted = v ?? false;
                          if (_accepted) _termsError = false;
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Use',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' (Data Privacy Act, RA 10173). My documents will be used only for my parking permit.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_termsError)
                  const Padding(
                    padding: EdgeInsets.only(top: 6, left: 34),
                    child: Text(
                      'Please accept the Terms and Privacy Notice to continue.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Register',
                  showArrow: true,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SecurityFooter(),
    );
  }
}