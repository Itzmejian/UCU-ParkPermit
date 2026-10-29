import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/date_format.dart';
import '../../core/pangasinan_address.dart';
import '../../core/ucu_programs.dart';
import '../../core/validators.dart';
import '../../models/network_store.dart';
import '../../models/profile_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/option_sheet.dart';
import '../../widgets/search_sheet.dart';

const List<String> _yearLevels = [
  '1st Year',
  '2nd Year',
  '3rd Year',
  '4th Year',
  '5th Year or higher',
];

const List<String> _employeeTypes = ['Instructor / Faculty', 'Staff'];

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _program = TextEditingController();
  final TextEditingController _other = TextEditingController();
  final TextEditingController _year = TextEditingController();
  final TextEditingController _empType = TextEditingController();
  final TextEditingController _dept = TextEditingController();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _barangay = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _province = TextEditingController(text: kProvince);
  bool _loading = false;

  bool get _programIsOther => _program.text == kOtherProgram;

  @override
  void initState() {
    super.initState();
    final p = ProfileStore.instance;
    _name.text = p.fullName;
    _phone.text = p.phone;
    _year.text = p.yearLevel;
    _empType.text = p.employeeType;
    _dept.text = p.department;
    _street.text = p.street;

    // A course typed before the dropdown existed is kept as "Other".
    final prog = p.program.trim();
    if (prog.isEmpty) {
      _program.text = '';
    } else if (kUcuProgramOptions.contains(prog)) {
      _program.text = prog;
    } else {
      _program.text = '';
      _other.text = prog;
    }

    // Only addresses from the Pangasinan list are kept; others must be chosen again.
    final city = matchPangasinanCity(p.city);
    _city.text = city ?? '';
    _barangay.text =
        city == null ? '' : (matchPangasinanBarangay(city, p.barangay) ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name, _phone, _program, _other, _year, _empType, _dept,
      _street, _barangay, _city, _province,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickYear() async {
    FocusScope.of(context).unfocus();
    final choice = await showOptionSheet(
      context,
      title: 'Year level',
      options: _yearLevels,
      selected: _year.text,
    );
    if (choice != null) setState(() => _year.text = choice);
  }

  Future<void> _pickEmpType() async {
    FocusScope.of(context).unfocus();
    final choice = await showOptionSheet(
      context,
      title: 'Employee type',
      options: _employeeTypes,
      selected: _empType.text,
    );
    if (choice != null) setState(() => _empType.text = choice);
  }

  Future<void> _pickProgram() async {
    final choice = await showSearchSheet(
      context,
      title: 'Course / Program',
      options: kUcuProgramOptions,
      subtitles: kUcuProgramNames,
      selected: _program.text,
      searchHint: 'Search, e.g., BSIT or Nursing',
    );
    if (choice != null) setState(() => _program.text = choice);
  }

  Future<void> _pickCity() async {
    final choice = await showSearchSheet(
      context,
      title: 'City / Municipality',
      options: kPangasinanCities,
      selected: _city.text,
      searchHint: 'Search, e.g., Urdaneta',
    );
    if (choice == null || choice == _city.text) return;
    setState(() {
      _city.text = choice;
      _barangay.clear();
    });
  }

  Future<void> _pickBarangay() async {
    final city = _city.text;
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
      selected: _barangay.text,
      searchHint: 'Search barangay',
    );
    if (choice != null) setState(() => _barangay.text = choice);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    final p = ProfileStore.instance;
    final program = p.isStudent
        ? (_programIsOther ? _other.text.trim() : _program.text.trim())
        : p.program;
    final result = await AuthService.saveEditableProfile(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      program: program,
      yearLevel: _year.text.trim(),
      employeeType: _empType.text.trim(),
      department: _dept.text.trim(),
      street: _street.text.trim(),
      barangay: _barangay.text.trim(),
      city: _city.text.trim(),
      province: kProvince,
    );
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not save your changes.')),
      );
      return;
    }
    ProfileStore.instance.updateEditable(
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      program: program,
      yearLevel: _year.text.trim(),
      employeeType: _empType.text.trim(),
      department: _dept.text.trim(),
      street: _street.text.trim(),
      barangay: _barangay.text.trim(),
      city: _city.text.trim(),
      province: kProvince,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
    Navigator.pop(context);
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
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
          const Expanded(child: Divider(color: AppColors.border, height: 1)),
        ],
      ),
    );
  }

  Widget _readOnlyRow(String label, String value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ProfileStore.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
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
                _section('Personal'),
                AppTextField(
                  label: 'Full Name',
                  hint: 'e.g., Juan Dela Cruz',
                  icon: Icons.person_outline,
                  controller: _name,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.fullName,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Mobile Number',
                  hint: '917 123 4567',
                  icon: Icons.phone_outlined,
                  prefixLabel: '+63',
                  controller: _phone,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.mobile,
                ),
                const SizedBox(height: 8),
                if (p.isStudent) ...[
                  _section('Student details'),
                  AppTextField(
                    label: 'Course / Program',
                    hint: 'Select your course',
                    icon: Icons.school_outlined,
                    controller: _program,
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
                      controller: _other,
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
                    controller: _year,
                    isRequired: true,
                    readOnly: true,
                    onTap: _pickYear,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please choose your year level'
                        : null,
                  ),
                ] else ...[
                  _section('Employee details'),
                  AppTextField(
                    label: 'Employee Type',
                    hint: 'Select your employee type',
                    icon: Icons.work_outline,
                    controller: _empType,
                    isRequired: true,
                    readOnly: true,
                    onTap: _pickEmpType,
                    trailingIcon: Icons.keyboard_arrow_down_rounded,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Please choose your employee type'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Department / Office',
                    hint: 'e.g., College of Computer Studies',
                    icon: Icons.apartment_outlined,
                    controller: _dept,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => Validators.required(v, 'Department / Office'),
                  ),
                ],
                const SizedBox(height: 8),
                _section('Home address'),
                AppTextField(
                  label: 'Province',
                  hint: kProvince,
                  icon: Icons.map_outlined,
                  controller: _province,
                  isRequired: true,
                  readOnly: true,
                  trailingIcon: Icons.lock_outline,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'City / Municipality',
                  hint: 'Select your city or municipality',
                  icon: Icons.location_city_outlined,
                  controller: _city,
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
                  hint: _city.text.isEmpty
                      ? 'Choose your city first'
                      : 'Select your barangay',
                  icon: Icons.location_on_outlined,
                  controller: _barangay,
                  isRequired: true,
                  readOnly: true,
                  onTap: _pickBarangay,
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  validator: (v) =>
                      matchPangasinanBarangay(_city.text, v ?? '') == null
                          ? 'Please choose your barangay'
                          : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Street / Purok (optional)',
                  hint: 'e.g., 123 Rizal Street or Purok 3',
                  icon: Icons.home_outlined,
                  controller: _street,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 8),
                _section('Cannot be edited here'),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _readOnlyRow('Email', p.email),
                      _readOnlyRow('User type', p.roleLabel),
                      _readOnlyRow(
                        p.isStudent ? 'Student ID' : 'Employee ID',
                        p.idNumber,
                      ),
                      _readOnlyRow(
                        'Birthday',
                        p.birthday == null ? '' : formatLongDate(p.birthday!),
                        last: true,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'These details were checked against your UCU ID. To change them, contact the Campus Security Office.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Save Changes',
                  showArrow: true,
                  isLoading: _loading,
                  onPressed: _save,
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