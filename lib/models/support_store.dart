import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

class SupportTicket {
  const SupportTicket({
    required this.ticketNo,
    required this.category,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  final String ticketNo;
  final String category;
  final String subject;
  final String message;
  final DateTime createdAt;
}

/// Contact Support inquiries. They are loaded from Supabase when connected,
/// and kept in memory in prototype mode.
class SupportStore extends ChangeNotifier {
  SupportStore._();

  static final SupportStore instance = SupportStore._();

  final List<SupportTicket> _tickets = [];

  List<SupportTicket> get tickets => List<SupportTicket>.unmodifiable(_tickets);

  /// Prototype mode only.
  SupportTicket create({
    required String category,
    required String subject,
    required String message,
  }) {
    final now = DateTime.now();
    final number = 1 + _tickets.length;
    final ticket = SupportTicket(
      ticketNo: 'SUP-${now.year}-${number.toString().padLeft(4, '0')}',
      category: category,
      subject: subject,
      message: message,
      createdAt: now,
    );
    _tickets.insert(0, ticket);
    notifyListeners();
    return ticket;
  }

  Future<void> loadRemote() async {
    if (!kSupabaseReady) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('support_tickets')
          .select('ticket_no, topic, subject, message, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      final list = (rows as List).cast<Map<String, dynamic>>();
      _tickets
        ..clear()
        ..addAll(
          list.map(
            (r) => SupportTicket(
              ticketNo: (r['ticket_no'] as String?) ?? '-',
              category: (r['topic'] as String?) ?? '',
              subject: (r['subject'] as String?) ?? '',
              message: (r['message'] as String?) ?? '',
              createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '')?.toLocal() ??
                  DateTime.now(),
            ),
          ),
        );
      notifyListeners();
    } catch (_) {}
  }

  void clear() {
    _tickets.clear();
    notifyListeners();
  }
}