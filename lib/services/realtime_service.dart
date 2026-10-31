import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/permissions.dart';
import '../core/supabase_config.dart';
import '../models/notification_store.dart';
import 'data_service.dart';

/// Listens to changes in the database, so the app updates by itself.
class RealtimeService {
  RealtimeService._();

  static RealtimeChannel? _notifChannel;
  static RealtimeChannel? _dataChannel;
  static Timer? _debounce;

  static PostgresChangeFilter _eq(String column, String value) {
    return PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: column,
      value: value,
    );
  }

  static void start() {
    requestNotificationPermission();
    if (!kSupabaseReady) return;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    stop();

    // New notifications appear in the bell right away.
    _notifChannel = client
        .channel('notifications-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: _eq('user_id', uid),
          callback: (payload) {
            NotificationStore.instance.addRemote(payload.newRecord);
          },
        )
        .subscribe();

    // Any change to the user's application, permit or vehicle reloads the data.
    void onData(PostgresChangePayload payload) => _scheduleRefresh();
    _dataChannel = client
        .channel('data-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'applications',
          filter: _eq('applicant_id', uid),
          callback: onData,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'permits',
          filter: _eq('owner_id', uid),
          callback: onData,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'vehicles',
          filter: _eq('owner_id', uid),
          callback: onData,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sticker_replacements',
          filter: _eq('owner_id', uid),
          callback: onData,
        )
        .subscribe();
  }

  static void stop() {
    _debounce?.cancel();
    _debounce = null;
    if (!kSupabaseReady) return;
    final client = Supabase.instance.client;
    final n = _notifChannel;
    final d = _dataChannel;
    _notifChannel = null;
    _dataChannel = null;
    if (n != null) client.removeChannel(n);
    if (d != null) client.removeChannel(d);
  }

  // Several changes often arrive together, so wait a moment and load once.
  static void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      DataService.refresh();
    });
  }
}