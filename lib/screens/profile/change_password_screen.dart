import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/validators.dart';
import '../../models/profile_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _new = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateNew(String? v) {
    final base = Validators.password(v);
    if (base != null) return base;
    if (v == _current.text) return 'Choose a password different from your current one';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: check the current password and update it with Supabase.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    SettingsStore.instance.markPasswordChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password updated.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Set a new password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your current password, then choose a new one.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
                ),
                const SizedBox(height: 22),
                AppTextField(
                  label: 'Current Password',
                  hint: 'Enter your current password',
                  icon: Icons.lock_outline,
                  controller: _current,
                  isRequired: true,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.loginPassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New Password',
                  hint: 'Create a new password',
                  icon: Icons.lock_reset_outlined,
                  controller: _new,
                  isRequired: true,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: _validateNew,
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
                  controller: _confirm,
                  isRequired: true,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => Validators.confirmPassword(v, _new.text),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Update Password',
                  showArrow: true,
                  isLoading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}