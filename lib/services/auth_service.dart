import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../core/signup_info.dart';
import '../core/supabase_config.dart';
import '../models/profile_store.dart';
import '../models/notification_store.dart';
import '../models/support_store.dart';
import 'data_service.dart';
import 'realtime_service.dart';

class AuthResult {
  const AuthResult.success()
      : ok = true,
        error = null,
        needsVerification = false;

  const AuthResult.failure(this.error, {this.needsVerification = false})
      : ok = false;

  final bool ok;
  final String? error;

  /// True when the account exists but the email is not verified yet.
  final bool needsVerification;
}

/// All sign in, sign up and profile calls to Supabase live here.
/// When Supabase is not set up yet, every method works in prototype mode.
class AuthService {
  AuthService._();

  static bool get live => kSupabaseReady;

  static SupabaseClient get _client => Supabase.instance.client;

  /// The code type that confirms a new account. Supabase now uses "email".
  /// If the code check ever fails with a type error, try OtpType.signup.
  static const OtpType _signupCodeType = OtpType.email;

  static String _roleToDb(String role) =>
      role == kRoleEmployee ? 'employee' : 'student';

  static Future<void> _fake() =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  static String _friendly(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login')) return 'Wrong email or password.';
      if (m.contains('email not confirmed')) {
        return 'Please verify your email first.';
      }
      if (m.contains('already registered') ||
          m.contains('already been registered')) {
        return 'This email is already registered. Try logging in.';
      }
      if (m.contains('rate limit') ||
          m.contains('too many') ||
          m.contains('security purposes') ||
          e.statusCode?.toString() == '429') {
        return 'Too many requests. Please wait a minute and try again.';
      }
      if (m.contains('token') && (m.contains('expired') || m.contains('invalid'))) {
        return 'The code is incorrect or has expired.';
      }
      if (m.contains('same password') || m.contains('different from the old')) {
        return 'Choose a password different from your current one.';
      }
      return e.message;
    }
    if (e is PostgrestException) {
      if (e.code == '23505') {
        return 'This ID number is already registered to another account.';
      }
      return e.message;
    }
    return 'Something went wrong. Check your internet connection and try again.';
  }

  // ---------- sign up and verification ----------

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': _roleToDb(role)},
      );
      final user = res.user;
      if (user != null && (user.identities?.isEmpty ?? false)) {
        return const AuthResult.failure(
          'This email is already registered. Try logging in.',
        );
      }
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  static Future<AuthResult> verifySignupCode({
    required String email,
    required String code,
  }) async {
    if (!live) {
      await _fake();
      return code == kDevOtp
          ? const AuthResult.success()
          : const AuthResult.failure('Incorrect or expired code. Please try again.');
    }
    try {
      final res = await _client.auth.verifyOTP(
        type: _signupCodeType,
        token: code,
        email: email,
      );
      if (res.session == null) {
        return const AuthResult.failure('Could not verify the code. Please try again.');
      }
      await loadProfile();
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  static Future<AuthResult> resendSignupCode(String email) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  // ---------- sign in and out ----------

  static Future<AuthResult> signIn(String email, String password) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session == null) {
        return const AuthResult.failure('Could not log in. Please try again.');
      }
      await loadProfile();
      return const AuthResult.success();
    } catch (e) {
      final unconfirmed =
          e is AuthException && e.message.toLowerCase().contains('email not confirmed');
      if (unconfirmed) {
        try {
          await _client.auth.resend(type: OtpType.signup, email: email);
        } catch (_) {}
      }
      return AuthResult.failure(_friendly(e), needsVerification: unconfirmed);
    }
  }

  static Future<void> signOut() async {
    if (!live) return;
    try {
      await _client.auth.signOut();
      DataService.clear();
      RealtimeService.stop();
      NotificationStore.instance.clear();
      SupportStore.instance.clear();
    } catch (_) {}
  }

  // ---------- profile ----------

  static Future<void> loadProfile() async {
    if (!live) return;
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (row != null) ProfileStore.instance.loadFromMap(row);
      await DataService.refresh(initial: true);
      await NotificationStore.instance.loadRemote();
      await SupportStore.instance.loadRemote();
      RealtimeService.start();
    } catch (_) {}
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Saves what the Complete Profile screen put in the ProfileStore.
  static Future<AuthResult> saveProfileDetails() async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    final user = _client.auth.currentUser;
    if (user == null) return const AuthResult.failure('Please log in again.');
    final p = ProfileStore.instance;
    try {
      await _client.from('profiles').update({
        'id_number': p.idNumber,
        'program': p.program,
        'year_level': p.yearLevel,
        'employee_type': p.employeeType,
        'department': p.department,
        'birthday': p.birthday == null ? null : _date(p.birthday!),
        'street': p.street,
        'barangay': p.barangay,
        'city': p.city,
        'province': p.province,
        'phone': p.phone,
        'profile_completed': true,
      }).eq('id', user.id);
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  static Future<AuthResult> saveEditableProfile({
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
  }) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    final user = _client.auth.currentUser;
    if (user == null) return const AuthResult.failure('Please log in again.');
    try {
      await _client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'program': program,
        'year_level': yearLevel,
        'employee_type': employeeType,
        'department': department,
        'street': street,
        'barangay': barangay,
        'city': city,
        'province': province,
      }).eq('id', user.id);
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  // ---------- passwords ----------

  static Future<AuthResult> sendResetCode(String email) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    try {
      await _client.auth.resetPasswordForEmail(email);
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  static Future<AuthResult> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (!live) {
      await _fake();
      return code == kDevOtp
          ? const AuthResult.success()
          : const AuthResult.failure('Incorrect or expired code. Please try again.');
    }
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: code,
        email: email,
      );
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await _client.auth.signOut();
      DataService.clear();
      RealtimeService.stop();
      NotificationStore.instance.clear();
      SupportStore.instance.clear();
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }

  static Future<AuthResult> changePassword({
    required String current,
    required String next,
  }) async {
    if (!live) {
      await _fake();
      return const AuthResult.success();
    }
    final email = _client.auth.currentUser?.email;
    if (email == null) return const AuthResult.failure('Please log in again.');
    try {
      try {
        await _client.auth.signInWithPassword(email: email, password: current);
      } on AuthException {
        return const AuthResult.failure('Your current password is incorrect.');
      }
      await _client.auth.updateUser(UserAttributes(password: next));
      return const AuthResult.success();
    } catch (e) {
      return AuthResult.failure(_friendly(e));
    }
  }
}