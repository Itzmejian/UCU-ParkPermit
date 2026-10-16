import 'package:flutter/foundation.dart';
import '../core/signup_info.dart';

/// The signed-in user's profile. In-memory until the app uses Supabase.
/// The sample values below are shown only until someone registers.
class ProfileStore extends ChangeNotifier {
  ProfileStore._();

  static final ProfileStore instance = ProfileStore._();

  String fullName = 'Juan Dela Cruz';
  String email = 'juan@example.com';
  String role = kRoleStudent;
  String idNumber = '2021-10482';
  String program = 'BS Information Technology';
  String yearLevel = '3rd Year';
  String employeeType = '';
  String department = '';
  DateTime? birthday = DateTime(2004, 5, 12);
  String street = '123 Rizal Street';
  String barangay = 'Poblacion';
  String city = 'Urdaneta City';
  String province = 'Pangasinan';
  String phone = '9171234567';

  bool get isStudent => role == kRoleStudent;

  String get roleLabel => isStudent ? 'Student' : 'Employee';

  String get roleBadge => isStudent ? 'STUDENT APPLICANT' : 'EMPLOYEE APPLICANT';

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'there';
    return parts.first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String get phoneDisplay {
    if (phone.length == 10) {
      return '+63 ${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone.isEmpty ? '-' : phone;
  }

  String get addressLine {
    final parts = [street, barangay, city, province]
        .where((p) => p.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  String get detailLine {
    final parts = isStudent
        ? [program, yearLevel]
        : [employeeType, department];
    final text = parts.where((p) => p.trim().isNotEmpty).join('  \u2022  ');
    return text.isEmpty ? '-' : text;
  }

  /// Called when someone registers. Starts a clean profile.
  void setAccount({
    required String fullName,
    required String email,
    required String role,
  }) {
    this.fullName = fullName;
    this.email = email;
    this.role = role;
    idNumber = '';
    program = '';
    yearLevel = '';
    employeeType = '';
    department = '';
    birthday = null;
    street = '';
    barangay = '';
    city = '';
    province = '';
    phone = '';
    notifyListeners();
  }

  /// Called when the Complete Profile screen is saved.
  void setDetails({
    required String idNumber,
    required String program,
    required String yearLevel,
    required String employeeType,
    required String department,
    required DateTime? birthday,
    required String street,
    required String barangay,
    required String city,
    required String province,
    required String phone,
  }) {
    this.idNumber = idNumber;
    this.program = program;
    this.yearLevel = yearLevel;
    this.employeeType = employeeType;
    this.department = department;
    this.birthday = birthday;
    this.street = street;
    this.barangay = barangay;
    this.city = city;
    this.province = province;
    this.phone = phone;
    notifyListeners();
  }

  /// Called by Edit Profile. Email, role, ID number and birthday stay as they are.
  void updateEditable({
    required String fullName,
    required String phone,
    required String program,
    required String yearLevel,
    required String employeeType,
    required String department,
    required String street,
    required String barangay,
    required String city,
    required String province,
  }) {
    this.fullName = fullName;
    this.phone = phone;
    this.program = program;
    this.yearLevel = yearLevel;
    this.employeeType = employeeType;
    this.department = department;
    this.street = street;
    this.barangay = barangay;
    this.city = city;
    this.province = province;
    notifyListeners();
  }
}

/// App settings (notification choices and password date).
class SettingsStore extends ChangeNotifier {
  SettingsStore._();

  static final SettingsStore instance = SettingsStore._();

  bool permitUpdates = true;
  bool stickerReminders = true;
  bool expiryReminders = true;
  bool accountActivity = true;
  DateTime? passwordUpdatedAt;

  void setPermitUpdates(bool v) {
    permitUpdates = v;
    notifyListeners();
  }

  void setStickerReminders(bool v) {
    stickerReminders = v;
    notifyListeners();
  }

  void setExpiryReminders(bool v) {
    expiryReminders = v;
    notifyListeners();
  }

  void setAccountActivity(bool v) {
    accountActivity = v;
    notifyListeners();
  }

  void markPasswordChanged() {
    passwordUpdatedAt = DateTime.now();
    notifyListeners();
  }
}