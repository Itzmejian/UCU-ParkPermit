import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/pangasinan_address.dart';
import '../../core/profile_validators.dart';
import '../../core/signup_info.dart';
import '../../core/ucu_programs.dart';
import '../../core/validators.dart';
import '../../models/network_store.dart';
import '../../models/profile_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/option_sheet.dart';
import '../../widgets/search_sheet.dart';
import '../../widgets/security_footer.dart';

/// Applicants must be at least this old (a driver's license is required).
const int _minAge = 16;

const List<String> _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _yearLevels = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
  '5th Year or higher',
];

const List<String> _employeeTypes = [
  'Instructor / Faculty',
  'Staff',
];

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _programCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _empTypeCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _barangayCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController(text: kProvince);
  final _phoneCtrl = TextEditingController();

  // Chosen on the Register screen. Defaults to Student if opened directly.
  String _role = kRoleStudent;
  bool _argsRead = false;
  DateTime? _birthday;
  bool _loading = false;

  bool get _isStudent => _role == kRoleStudent;
  bool get _programIsOther => _programCtrl.text == kOtherProgram;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is SignupInfo) {
      _role = arg.role;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _idCtrl, _programCtrl, _otherCtrl, _yearCtrl, _empTypeCtrl, _deptCtrl,
      _birthCtrl, _streetCtrl, _barangayCtrl, _cityCtrl, _provinceCtrl, _phoneCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  int _ageOn(DateTime on, DateTime birth) {
    int age = on.year - birth.year;
    if (on.month < birth.month ||
        (on.month == birth.month && on.day < birth.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1950),
      lastDate: now,
      helpText: 'Select your birthday',
    );
    if (picked == null) return;
    setState(() {
      _birthday = picked;
      _birthCtrl.text = _formatDate(picked);
    });
  }

  Future<void> _pickYearLevel() async {
    FocusScope.of(context).unfocus();
    final choice = await showOptionSheet(
      context,
      title: 'Year level',
      options: _yearLevels,
      selected: _yearCtrl.text,
    );
    if (choice != null) setState(() => _yearCtrl.text = choice);
  }

  Future<void> _pickEmployeeType() async {
    FocusScope.of(context).unfocus();
    final choice = await showOptionSheet(
      context,
      title: 'Employee type',
      options: _employeeTypes,
      selected: _empTypeCtrl.text,
    );
    if (choice != null) setState(() => _empTypeCtrl.text = choice);
  }

  Future<void> _pickProgram() async {
    final choice = await showSearchSheet(
      context,
      title: 'Course / Program',
      options: kUcuProgramOptions,
      subtitles: kUcuProgramNames,
      selected: _programCtrl.text,
      searchHint: 'Search, e.g., BSIT or Nursing',
    );
    if (choice != null) setState(() => _programCtrl.text = choice);
  }

  Future<void> _pickCity() async {
    final choice = await showSearchSheet(
      context,
      title: 'City / Municipality',
      options: kPangasinanCities,
      selected: _cityCtrl.text,
      searchHint: 'Search, e.g., Urdaneta',
    );
    if (choice == null || choice == _cityCtrl.text) return;
    setState(() {
      _cityCtrl.text = choice;
      _barangayCtrl.clear();
    });
  }

  Future<void> _pickBarangay() async {
    final city = _cityCtrl.text;
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose your city or municipality first.')),
      );
      return;
    }
    final choice = await showSearchSheet(
      context,
      title: 'Barangay in $city',
      options: kPangasinanBarangays[city] ?? const <String>[],
      selected: _barangayCtrl.text,
      searchHint: 'Search barangay',
    );
    if (choice != null) setState(() => _barangayCtrl.text = choice);
  }

  String? _validateBirthday(String? value) {
    if (_birthday == null) return 'Birthday is required';
    if (_ageOn(DateTime.now(), _birthday!) < _minAge) {
      return 'You must be at least $_minAge years old to apply.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    final program = !_isStudent
        ? ''
        : (_programIsOther ? _otherCtrl.text.trim() : _programCtrl.text.trim());
    ProfileStore.instance.setDetails(
      idNumber: _idCtrl.text.trim(),
      program: program,
      yearLevel: _isStudent ? _yearCtrl.text.trim() : '',
      employeeType: _isStudent ? '' : _empTypeCtrl.text.trim(),
      department: _isStudent ? '' : _deptCtrl.text.trim(),
      birthday: _birthday,
      street: _streetCtrl.text.trim(),
      barangay: _barangayCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      province: kProvince,
      phone: _phoneCtrl.text.trim(),
    );
    final result = await AuthService.saveProfileDetails();
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not save your profile.')),
      );
      return;
    }
    setState(() => _loading = false);
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  List<Widget> _roleFields() {
    if (_isStudent) {
      return [
        const _SectionTitle('Student details'),
        AppTextField(
          label: 'Student ID Number',
          hint: 'e.g., 20240001',
          icon: Icons.badge_outlined,
          controller: _idCtrl,
          isRequired: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: ProfileValidators.studentId,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            '8 digits. The first 4 are your entry year.',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Course / Program',
          hint: 'Select your course',
          icon: Icons.school_outlined,
          controller: _programCtrl,
          isRequired: true,
          readOnly: true,
          onTap: _pickProgram,
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please choose your course' : null,
        ),
        if (_programIsOther) ...[
          const SizedBox(height: 16),
          AppTextField(
            label: 'Your Course',
            hint: 'Type the name of your course',
            icon: Icons.edit_outlined,
            controller: _otherCtrl,
            isRequired: true,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Course name'),
          ),
        ],
        const SizedBox(height: 16),
        AppTextField(
          label: 'Year Level',
          hint: 'Select your year level',
          icon: Icons.stairs_outlined,
          controller: _yearCtrl,
          isRequired: true,
          readOnly: true,
          onTap: _pickYearLevel,
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please choose your year level' : null,
        ),
      ];
    }

    return [
      const _SectionTitle('Employee details'),
      AppTextField(
        label: 'Employee ID Number',
        hint: 'e.g., EMP-2023-012',
        icon: Icons.badge_outlined,
        controller: _idCtrl,
        isRequired: true,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.characters,
        validator: Validators.idNumber,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Employee Type',
        hint: 'Select your employee type',
        icon: Icons.work_outline,
        controller: _empTypeCtrl,
        isRequired: true,
        readOnly: true,
        onTap: _pickEmployeeType,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
        validator: (v) =>
            (v == null || v.isEmpty) ? 'Please choose your employee type' : null,
      ),
      const SizedBox(height: 16),
      AppTextField(
        label: 'Department / Office',
        hint: 'e.g., College of Computer Studies',
        icon: Icons.apartment_outlined,
        controller: _deptCtrl,
        isRequired: true,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        validator: (v) => Validators.required(v, 'Department / Office'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Complete your profile',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us about yourself. You only do this once. These details are reused for every vehicle you register.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isStudent ? Icons.school_outlined : Icons.work_outline,
                        size: 20,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                            children: [
                              const TextSpan(text: 'Registered as '),
                              TextSpan(
                                text: _isStudent
                                    ? 'Student'
                                    : 'Employee (instructor or staff)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._roleFields(),
                const SizedBox(height: 8),
                const _SectionTitle('Personal details'),
                AppTextField(
                  label: 'Birthday',
                  hint: 'Select your birthday',
                  icon: Icons.cake_outlined,
                  controller: _birthCtrl,
                  isRequired: true,
                  readOnly: true,
                  onTap: _pickBirthday,
                  trailingIcon: Icons.calendar_month_outlined,
                  validator: _validateBirthday,
                ),
                const SizedBox(height: 8),
                const _SectionTitle('Home address'),
                AppTextField(
                  label: 'Province',
                  hint: kProvince,
                  icon: Icons.map_outlined,
                  controller: _provinceCtrl,
                  isRequired: true,
                  readOnly: true,
                  trailingIcon: Icons.lock_outline,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Only addresses in Pangasinan are accepted.',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'City / Municipality',
                  hint: 'Select your city or municipality',
                  icon: Icons.location_city_outlined,
                  controller: _cityCtrl,
                  isRequired: true,
                  readOnly: true,
                  onTap: _pickCity,
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  validator: (v) => matchPangasinanCity(v ?? '') == null
                      ? 'Please choose your city or municipality'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Barangay',
                  hint: _cityCtrl.text.isEmpty
                      ? 'Choose your city first'
                      : 'Select your barangay',
                  icon: Icons.location_on_outlined,
                  controller: _barangayCtrl,
                  isRequired: true,
                  readOnly: true,
                  onTap: _pickBarangay,
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  validator: (v) =>
                      matchPangasinanBarangay(_cityCtrl.text, v ?? '') == null
                          ? 'Please choose your barangay'
                          : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Street / Purok (optional)',
                  hint: 'e.g., 123 Rizal Street or Purok 3',
                  icon: Icons.home_outlined,
                  controller: _streetCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                const _SectionTitle('Contact'),
                AppTextField(
                  label: 'Mobile Number',
                  hint: '917 123 4567',
                  icon: Icons.phone_outlined,
                  prefixLabel: '+63',
                  controller: _phoneCtrl,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.mobile,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.goldDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The Campus Security Office checks these details against your UCU ID when you submit your first application. Make sure they are correct.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Save and continue',
                  showArrow: true,
                  isLoading: _loading,
                  onPressed: _submit,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(color: AppColors.border, height: 1),
          ),
        ],
      ),
    );
  }
}