import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/pangasinan_address.dart';
import '../../core/validators.dart';
import '../../services/guard_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/option_sheet.dart';
import '../../widgets/otp_input.dart';
import '../../widgets/search_sheet.dart';

/// A guard creates their account after the Security Office invites them:
/// 1 email, 2 the 6-digit code from the invite email, 3 check and correct
/// the details the admin entered, 4 create a password.
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

  // Details (step 3)
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _suffix = TextEditingController();
  final _phone = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _sex = TextEditingController();
  final _province = TextEditingController(text: kProvince);
  final _city = TextEditingController();
  final _barangay = TextEditingController();
  final _street = TextEditingController();
  DateTime? _birth;
  String _original = '';

  int _step = 0; // 0 email, 1 code, 2 details, 3 password
  bool _busy = false;
  String? _error;
  String? _info;
  Map<String, dynamic> _profile = {};

  SupabaseClient get _c => Supabase.instance.client;

  static const _titles = ['Your email', 'Enter the code', 'Check your details', 'Create your password'];
  static const _suffixes = ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV', 'V'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void dispose() {
    for (final c in [
      _email, _code, _pw, _pw2, _first, _middle, _last, _suffix, _phone,
      _birthCtrl, _sex, _province, _city, _barangay, _street,
    ]) {
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
    if (raw.contains('BAD_PHONE')) return 'Enter a valid mobile number.';
    if (raw.contains('BAD_BIRTHDATE')) return 'Check your birthday. Guards must be at least 18 years old.';
    if (raw.contains('BAD_ADDRESS')) return 'Choose your city or municipality and barangay.';
    if (raw.contains('BAD_NAME')) return 'Enter your first name and last name.';
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
    final ok = await _run(
      () => _c.auth.signInWithOtp(email: _email.text.trim().toLowerCase(), shouldCreateUser: false),
    );
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
      await _c.auth.verifyOTP(type: OtpType.email, email: _email.text.trim().toLowerCase(), token: code);
      try {
        _profile = await GuardService.myProfile();
      } catch (e) {
        await _signOutQuietly();
        rethrow;
      }
      if (_profile['active'] != true) {
        await _signOutQuietly();
        stop = 'Your guard account is not active. Contact the Security Office.';
      }
    });
    if (!mounted || !ok) return;
    if (stop != null) {
      setState(() => _error = stop);
      return;
    }
    _fillDetails();
    setState(() => _step = 2);
  }

  // ---------- step 3: details ----------

  String _s(String key) => (_profile[key] ?? '').toString().trim();

  String _fmtBirth(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  String _birthIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _fillDetails() {
    _first.text = _s('first_name');
    _middle.text = _s('middle_name');
    _last.text = _s('last_name');
    _suffix.text = _s('suffix').isEmpty ? 'None' : _s('suffix');
    final phone = _s('phone');
    _phone.text = phone.startsWith('0') ? phone.substring(1) : phone;
    _birth = DateTime.tryParse(_s('birthdate'));
    _birthCtrl.text = _birth == null ? '' : _fmtBirth(_birth!);
    _sex.text = _s('sex');
    _city.text = matchPangasinanCity(_s('city')) ?? '';
    _barangay.text = _city.text.isEmpty ? '' : (matchPangasinanBarangay(_city.text, _s('barangay')) ?? '');
    _street.text = _s('street');
    _original = _details.toString();
  }

  Map<String, String> get _details => {
        'first_name': _first.text.trim(),
        'middle_name': _middle.text.trim(),
        'last_name': _last.text.trim(),
        'suffix': _suffix.text == 'None' ? '' : _suffix.text.trim(),
        'phone': _phone.text.trim().isEmpty ? '' : '0${_phone.text.trim()}',
        'birthdate': _birth == null ? '' : _birthIso(_birth!),
        'sex': _sex.text.trim(),
        'street': _street.text.trim(),
        'barangay': _barangay.text.trim(),
        'city': _city.text.trim(),
      };

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(now.year - 30, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Select your birthday',
    );
    if (picked == null) return;
    setState(() {
      _birth = picked;
      _birthCtrl.text = _fmtBirth(picked);
    });
  }

  Future<void> _pickSex() async {
    FocusScope.of(context).unfocus();
    final v = await showOptionSheet(context, title: 'Sex', options: const ['Male', 'Female'], selected: _sex.text);
    if (v != null) setState(() => _sex.text = v);
  }

  Future<void> _pickSuffix() async {
    FocusScope.of(context).unfocus();
    final v = await showOptionSheet(context, title: 'Suffix', options: _suffixes, selected: _suffix.text);
    if (v != null) setState(() => _suffix.text = v);
  }

  Future<void> _pickCity() async {
    final v = await showSearchSheet(
      context,
      title: 'City / Municipality',
      options: kPangasinanCities,
      selected: _city.text,
      searchHint: 'Search, e.g., Urdaneta',
    );
    if (v == null || v == _city.text) return;
    setState(() {
      _city.text = v;
      _barangay.clear();
    });
  }

  Future<void> _pickBarangay() async {
    if (_city.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose your city or municipality first.')),
      );
      return;
    }
    final v = await showSearchSheet(
      context,
      title: 'Barangay in ${_city.text}',
      options: kPangasinanBarangays[_city.text] ?? const <String>[],
      selected: _barangay.text,
      searchHint: 'Search barangay',
    );
    if (v != null) setState(() => _barangay.text = v);
  }

  Future<void> _saveDetails() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final d = _details;
    if (d.toString() == _original) {
      setState(() {
        _error = null;
        _step = 3;
      });
      return;
    }
    final ok = await _run(() => GuardService.updateMyProfile(d));
    if (!ok || !mounted) return;
    _original = d.toString();
    setState(() {
      _info = 'Your details were updated. The Security Office can see the change.';
      _step = 3;
    });
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
    if (_step == 1 || _step == 3) {
      setState(() {
        _step -= 1;
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.goldDark),
        ),
      );

  Widget _lockedRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.navy),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }

  Widget _detailsForm() {
    const gap = SizedBox(height: 14);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'The Campus Security Office entered these details for you. '
            'If something is wrong, fix it here. The Security Office will see your changes.',
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _lockedRow(Icons.badge_outlined, 'Guard ID', _s('id_no')),
                _lockedRow(Icons.mail_outline, 'Email', _s('email')),
              ],
            ),
          ),
          _sectionTitle('Name'),
          AppTextField(
            label: 'First name',
            hint: 'Juan',
            icon: Icons.person_outline,
            controller: _first,
            isRequired: true,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'First name'),
          ),
          gap,
          AppTextField(
            label: 'Middle name (optional)',
            hint: 'Santos',
            icon: Icons.person_outline,
            controller: _middle,
            textCapitalization: TextCapitalization.words,
          ),
          gap,
          AppTextField(
            label: 'Last name',
            hint: 'Dela Cruz',
            icon: Icons.person_outline,
            controller: _last,
            isRequired: true,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Last name'),
          ),
          gap,
          AppTextField(
            label: 'Suffix',
            hint: 'None',
            icon: Icons.short_text,
            controller: _suffix,
            readOnly: true,
            onTap: _pickSuffix,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
          ),
          _sectionTitle('Personal details'),
          AppTextField(
            label: 'Birthday',
            hint: 'Select your birthday',
            icon: Icons.cake_outlined,
            controller: _birthCtrl,
            isRequired: true,
            readOnly: true,
            onTap: _pickBirthday,
            trailingIcon: Icons.calendar_month_outlined,
            validator: (_) => _birth == null ? 'Birthday is required' : null,
          ),
          gap,
          AppTextField(
            label: 'Sex',
            hint: 'Select',
            icon: Icons.wc_outlined,
            controller: _sex,
            isRequired: true,
            readOnly: true,
            onTap: _pickSex,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            validator: (v) => Validators.required(v, 'Sex'),
          ),
          _sectionTitle('Home address'),
          AppTextField(
            label: 'Province',
            hint: kProvince,
            icon: Icons.map_outlined,
            controller: _province,
            isRequired: true,
            readOnly: true,
            trailingIcon: Icons.lock_outline,
          ),
          gap,
          AppTextField(
            label: 'City / Municipality',
            hint: 'Select your city or municipality',
            icon: Icons.location_city_outlined,
            controller: _city,
            isRequired: true,
            readOnly: true,
            onTap: _pickCity,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            validator: (v) => matchPangasinanCity(v ?? '') == null ? 'Please choose your city or municipality' : null,
          ),
          gap,
          AppTextField(
            label: 'Barangay',
            hint: _city.text.isEmpty ? 'Choose your city first' : 'Select your barangay',
            icon: Icons.location_on_outlined,
            controller: _barangay,
            isRequired: true,
            readOnly: true,
            onTap: _pickBarangay,
            trailingIcon: Icons.keyboard_arrow_down_rounded,
            validator: (v) =>
                matchPangasinanBarangay(_city.text, v ?? '') == null ? 'Please choose your barangay' : null,
          ),
          gap,
          AppTextField(
            label: 'Street / Purok (optional)',
            hint: 'e.g., 123 Rizal Street or Purok 3',
            icon: Icons.home_outlined,
            controller: _street,
            textCapitalization: TextCapitalization.words,
          ),
          _sectionTitle('Contact'),
          AppTextField(
            label: 'Mobile Number',
            hint: '917 123 4567',
            icon: Icons.phone_outlined,
            prefixLabel: '+63',
            controller: _phone,
            isRequired: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: Validators.mobile,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'Save and continue', showArrow: true, isLoading: _busy, onPressed: _saveDetails),
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
              'Your invite email "Your UCU ParkPermit guard account code" has a 6-digit code.',
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
              'Enter the 6-digit code sent to ${_email.text.trim()}. Check your Spam folder too.',
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
        return _detailsForm();
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Last step, ${_first.text.trim().isEmpty ? 'guard' : _first.text.trim()}. '
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
