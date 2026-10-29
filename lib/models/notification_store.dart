import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_routes.dart';
import '../core/supabase_config.dart';
import 'application_store.dart';
import 'permit_status.dart';
import 'profile_store.dart';

enum NotifKind { permit, sticker, expiry, account }

extension NotifKindInfo on NotifKind {
  bool get isPermit => this != NotifKind.account;
}

NotifKind notifKindFrom(String? s) {
  switch (s) {
    case 'sticker':
      return NotifKind.sticker;
    case 'expiry':
      return NotifKind.expiry;
    case 'account':
      return NotifKind.account;
    default:
      return NotifKind.permit;
  }
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.route,
    this.read = false,
  });

  final String id;
  final NotifKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  bool read;
}

/// The notification bell. When the app is connected to Supabase the server
/// creates the notifications and they arrive live. In prototype mode they are
/// created in the app from changes in the application store.
class NotificationStore extends ChangeNotifier {
  NotificationStore._() {
    if (!kSupabaseReady) {
      _items.add(
        NotificationItem(
          id: 'local-${_nextId++}',
          kind: NotifKind.account,
          title: 'Welcome to UCU ParkPermit',
          body: 'Your account is ready. Apply for your parking permit from the Home tab.',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
    }
    // Changing the notification preferences updates the list and the bell.
    SettingsStore.instance.addListener(notifyListeners);
  }

  static final NotificationStore instance = NotificationStore._();

  final List<NotificationItem> _items = [];
  int _nextId = 1;
  bool _started = false;
  bool muted = false;

  PermitStatus _lastStatus = PermitStatus.none;
  int _lastSubmitted = 0;
  AppealRecord? _lastAppeal;
  StickerReplacementRequest? _lastReplacement;

  bool _visible(NotificationItem n) {
    final s = SettingsStore.instance;
    return switch (n.kind) {
      NotifKind.permit => s.permitUpdates,
      NotifKind.sticker => s.stickerReminders,
      NotifKind.expiry => s.expiryReminders,
      NotifKind.account => s.accountActivity,
    };
  }

  List<NotificationItem> get items =>
      List<NotificationItem>.unmodifiable(_items.where(_visible));

  int get unreadCount => _items.where((n) => _visible(n) && !n.read).length;

  // ---------- server (live) ----------

  NotificationItem _fromRow(Map<String, dynamic> r) {
    return NotificationItem(
      id: r['id'] as String,
      kind: notifKindFrom(r['kind'] as String?),
      title: (r['title'] as String?) ?? '',
      body: (r['body'] as String?) ?? '',
      createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      route: r['route'] as String?,
      read: r['is_read'] == true,
    );
  }

  Future<void> loadRemote() async {
    if (!kSupabaseReady) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100);
      final list = (rows as List).cast<Map<String, dynamic>>();
      _items
        ..clear()
        ..addAll(list.map(_fromRow));
      notifyListeners();
    } catch (_) {}
  }

  /// A notification that just arrived from the server.
  void addRemote(Map<String, dynamic> row) {
    if (row['id'] == null) return;
    final item = _fromRow(row);
    if (_items.any((n) => n.id == item.id)) return;
    _items.insert(0, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<void> _pushRead(String id) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  Future<void> _pushReadAll() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return;
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false);
    } catch (_) {}
  }

  // ---------- reading ----------

  void markRead(String id) {
    for (final n in _items) {
      if (n.id == id && !n.read) {
        n.read = true;
        notifyListeners();
        if (kSupabaseReady && !id.startsWith('local-')) _pushRead(id);
        return;
      }
    }
  }

  void markAllRead() {
    var changed = false;
    for (final n in _items) {
      if (!n.read) {
        n.read = true;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      if (kSupabaseReady) _pushReadAll();
    }
  }

  // ---------- prototype mode ----------

  /// Starts watching the application store (prototype mode only).
  void ensureStarted() {
    if (_started || kSupabaseReady) return;
    _started = true;
    final app = ApplicationStore.instance;
    _lastStatus = app.status;
    _lastSubmitted = app.submittedList.length;
    _lastAppeal = app.lastAppeal;
    _lastReplacement = app.replacement;
    app.addListener(_onAppChanged);
  }

  /// Re-reads the application store without creating notifications.
  void rebase() {
    final app = ApplicationStore.instance;
    _lastStatus = app.status;
    _lastSubmitted = app.submittedList.length;
    _lastAppeal = app.lastAppeal;
    _lastReplacement = app.replacement;
  }

  void add({
    required NotifKind kind,
    required String title,
    required String body,
    String? route,
  }) {
    final now = DateTime.now();
    if (_items.isNotEmpty) {
      final latest = _items.first;
      if (latest.title == title && now.difference(latest.createdAt).inSeconds < 3) {
        return;
      }
    }
    _items.insert(
      0,
      NotificationItem(
        id: 'local-${_nextId++}',
        kind: kind,
        title: title,
        body: body,
        createdAt: now,
        route: route,
      ),
    );
    notifyListeners();
  }

  void _onAppChanged() {
    if (muted) return;
    final app = ApplicationStore.instance;
    final s = app.status;
    var handled = false;

    if (app.submittedList.length > _lastSubmitted) {
      final sub = app.submittedList.last;
      add(
        kind: NotifKind.permit,
        title: sub.isRenewal ? 'Renewal submitted' : 'Application submitted',
        body: 'Reference ${sub.referenceNo}. We will notify you when it is reviewed.',
        route: AppRoutes.applicationStatus,
      );
      handled = true;
    }

    final appeal = app.lastAppeal;
    if (appeal != null && !identical(appeal, _lastAppeal)) {
      add(
        kind: NotifKind.permit,
        title: 'Appeal received',
        body: 'Ticket ${appeal.ticketNo} is now under re-evaluation.',
        route: AppRoutes.applicationStatus,
      );
      handled = true;
    }

    final replacement = app.replacement;
    if (replacement != null && !identical(replacement, _lastReplacement)) {
      add(
        kind: NotifKind.sticker,
        title: 'Sticker replacement requested',
        body: 'The Security Office will review your request.',
        route: AppRoutes.permitDetails,
      );
    }

    if (!handled && s != _lastStatus) {
      _addStatusNotification(s);
    }

    _lastStatus = s;
    _lastSubmitted = app.submittedList.length;
    _lastAppeal = app.lastAppeal;
    _lastReplacement = app.replacement;
  }

  void _addStatusNotification(PermitStatus s) {
    switch (s) {
      case PermitStatus.none:
      case PermitStatus.draft:
        break;
      case PermitStatus.pending:
        add(
          kind: NotifKind.permit,
          title: 'Application received',
          body: 'Your application is waiting in the review queue.',
          route: AppRoutes.applicationStatus,
        );
        break;
      case PermitStatus.underReview:
        add(
          kind: NotifKind.permit,
          title: 'Application under review',
          body: 'An officer is checking your documents. This takes 24 to 48 hours.',
          route: AppRoutes.applicationStatus,
        );
        break;
      case PermitStatus.declined:
        add(
          kind: NotifKind.permit,
          title: 'Application declined',
          body: 'Your application needs a correction. You can file an appeal within 7 days.',
          route: AppRoutes.applicationDeclined,
        );
        break;
      case PermitStatus.appealReview:
        add(
          kind: NotifKind.permit,
          title: 'Appeal under review',
          body: 'The Security Office is re-checking your documents.',
          route: AppRoutes.applicationStatus,
        );
        break;
      case PermitStatus.approved:
        add(
          kind: NotifKind.permit,
          title: 'Permit approved',
          body: 'Your permit number was issued. Your sticker is being prepared.',
          route: AppRoutes.applicationApproved,
        );
        break;
      case PermitStatus.stickerReady:
        add(
          kind: NotifKind.sticker,
          title: 'Sticker ready for pickup',
          body: 'Claim your permit sticker at the Campus Security Office.',
          route: AppRoutes.stickerPickup,
        );
        break;
      case PermitStatus.active:
        add(
          kind: NotifKind.permit,
          title: 'Permit active',
          body: 'Your sticker was claimed and your permit is valid.',
          route: AppRoutes.permitDetails,
        );
        break;
      case PermitStatus.expiringSoon:
        add(
          kind: NotifKind.expiry,
          title: 'Permit expiring soon',
          body: 'Renew your permit so you can keep parking on campus.',
          route: AppRoutes.renewal,
        );
        break;
      case PermitStatus.expired:
        add(
          kind: NotifKind.expiry,
          title: 'Permit expired',
          body: 'Your permit has expired. Renew it to park on campus again.',
          route: AppRoutes.permitExpired,
        );
        break;
    }
  }
}