import 'package:flutter/foundation.dart';
import '../core/app_routes.dart';
import 'application_store.dart';
import 'permit_status.dart';
import 'profile_store.dart';

enum NotifKind { permit, sticker, expiry, account }

extension NotifKindInfo on NotifKind {
  bool get isPermit => this != NotifKind.account;
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

  final int id;
  final NotifKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? route;
  bool read;
}

/// In-app notifications. They are created from changes in the application
/// store, until the app gets real notifications from Supabase.
class NotificationStore extends ChangeNotifier {
  NotificationStore._() {
    _items.add(
      NotificationItem(
        id: _nextId++,
        kind: NotifKind.account,
        title: 'Welcome to UCU ParkPermit',
        body: 'Your account is ready. Apply for your parking permit from the Home tab.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
  }

  static final NotificationStore instance = NotificationStore._();

  final List<NotificationItem> _items = [];
  int _nextId = 1;
  bool _started = false;

  PermitStatus _lastStatus = PermitStatus.none;
  int _lastSubmitted = 0;
  AppealRecord? _lastAppeal;
  StickerReplacementRequest? _lastReplacement;

  List<NotificationItem> get items => List<NotificationItem>.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.read).length;

  /// Starts watching the application store. Safe to call more than once.
  void ensureStarted() {
    if (_started) return;
    _started = true;
    final app = ApplicationStore.instance;
    _lastStatus = app.status;
    _lastSubmitted = app.submittedList.length;
    _lastAppeal = app.lastAppeal;
    _lastReplacement = app.replacement;
    app.addListener(_onAppChanged);
  }

  bool _enabled(NotifKind kind) {
    final s = SettingsStore.instance;
    return switch (kind) {
      NotifKind.permit => s.permitUpdates,
      NotifKind.sticker => s.stickerReminders,
      NotifKind.expiry => s.expiryReminders,
      NotifKind.account => s.accountActivity,
    };
  }

  void add({
    required NotifKind kind,
    required String title,
    required String body,
    String? route,
  }) {
    if (!_enabled(kind)) return;
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
        id: _nextId++,
        kind: kind,
        title: title,
        body: body,
        createdAt: now,
        route: route,
      ),
    );
    notifyListeners();
  }

  void markRead(int id) {
    for (final n in _items) {
      if (n.id == id && !n.read) {
        n.read = true;
        notifyListeners();
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
    if (changed) notifyListeners();
  }

  void _onAppChanged() {
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