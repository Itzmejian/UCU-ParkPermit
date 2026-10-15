import 'constants.dart';

class Validators {
  Validators._();

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? fullName(String? value) {
    final r = required(value, 'Full name');
    if (r != null) return r;
    final parts = value!.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'Enter your first and last name';
    return null;
  }

  static String? email(String? value) {
    final r = required(value, 'Email');
    if (r != null) return r;
    final v = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Enter a valid email address';
    }
    if (kRequireUcuEmail && !v.toLowerCase().endsWith('@$kUcuEmailDomain')) {
      return 'Use your UCU email (e.g., username@$kUcuEmailDomain)';
    }
    return null;
  }

  static String? password(String? value) {
    final r = required(value, 'Password');
    if (r != null) return r;
    if (value!.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? loginPassword(String? value) {
    return required(value, 'Password');
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? idNumber(String? value) {
    final r = required(value, 'ID number');
    if (r != null) return r;
    final v = value!.trim();
    if (v.length < 4) return 'ID number is too short';
    if (!RegExp(r'^[A-Za-z0-9\-]+$').hasMatch(v)) {
      return 'Use letters, numbers and dashes only';
    }
    return null;
  }

  /// Philippine mobile number without the +63, e.g. 9171234567.
  static String? mobile(String? value) {
    final r = required(value, 'Contact number');
    if (r != null) return r;
    if (!RegExp(r'^9\d{9}$').hasMatch(value!.trim())) {
      return 'Enter a valid mobile number (e.g., 917 123 4567)';
    }
    return null;
  }
}