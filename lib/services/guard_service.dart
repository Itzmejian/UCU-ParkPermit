import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// The route of the guard's scanner screen.
const String kGuardRoute = '/guard';

/// Security guards: log in, check a sticker, and see the owner's ID photo.
/// Guard accounts are added by the developer in Supabase (public.guards).
class GuardService {
  GuardService._();

  static SupabaseClient get _c => Supabase.instance.client;

  static String friendly(Object e) {
    final m = e is PostgrestException ? e.message : e.toString();
    if (m.contains('NOT_GUARD')) return 'Your guard account is not active. Contact the Security Office.';
    if (m.contains('BAD_INPUT')) return 'Enter a permit number or plate number.';
    final low = m.toLowerCase();
    if (low.contains('socket') || low.contains('failed host') || low.contains('network')) {
      return 'No internet connection. Check the sticker and plate by hand for now.';
    }
    return 'Could not check the sticker. Please try again.';
  }

  static Future<bool> isGuard() async {
    if (!kSupabaseReady || _c.auth.currentUser == null) return false;
    try {
      return await _c.rpc('is_guard') == true;
    } catch (_) {
      return false;
    }
  }

  /// Returns an error message, or null when logged in as a guard.
  static Future<String?> signIn(String email, String password) async {
    if (!kSupabaseReady) return 'Guard login needs the server connection.';
    try {
      await _c.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      return e.message.toLowerCase().contains('invalid')
          ? 'Wrong email or password.'
          : e.message;
    } catch (_) {
      return 'Could not log in. Check your internet connection.';
    }
    if (!await isGuard()) {
      await signOut();
      return 'This is not a security guard account.';
    }
    return null;
  }

  static Future<void> signOut() async {
    try {
      await _c.auth.signOut();
    } catch (_) {}
  }

  static Future<String> guardName() async {
    try {
      final uid = _c.auth.currentUser?.id;
      if (uid == null) return '';
      final r = await _c.from('guards').select('full_name').eq('user_id', uid).maybeSingle();
      return (r?['full_name'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  /// Checks a sticker. [code] is the scanned QR text, a permit number or a plate.
  static Future<Map<String, dynamic>> verify(String code) async {
    final r = await _c.rpc('guard_verify', params: {'p_code': code});
    return Map<String, dynamic>.from(r as Map);
  }

  /// A short-lived link to the owner's UCU ID photo, or null.
  static Future<String?> photoUrl(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      return await _c.storage.from('documents').createSignedUrl(path, 300);
    } catch (_) {
      return null;
    }
  }
}