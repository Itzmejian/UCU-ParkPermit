import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'notification_store.dart';

/// Tracks whether the phone has a network connection. The black offline
/// banner listens to this. When the connection comes back, the data reloads.
class NetworkStore extends ChangeNotifier {
  NetworkStore._() {
    _start();
  }

  static final NetworkStore instance = NetworkStore._();

  bool _noNetwork = false;
  bool _simulated = false;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool get isOffline => _noNetwork || _simulated;

  Future<void> _start() async {
    final c = Connectivity();
    _sub = c.onConnectivityChanged.listen(_apply, onError: (Object _) {});
    try {
      _apply(await c.checkConnectivity());
    } catch (_) {}
  }

  void _apply(List<ConnectivityResult> results) {
    final none = results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (none == _noNetwork) return;
    final wasOffline = isOffline;
    _noNetwork = none;
    notifyListeners();
    if (wasOffline && !isOffline) _onBackOnline();
  }

  void _onBackOnline() {
    if (!DataService.live) return;
    DataService.refresh();
    NotificationStore.instance.loadRemote();
  }

  /// TESTING ONLY: pretend there is no internet (Profile, Testing only).
  void setOffline(bool value) {
    if (_simulated == value) return;
    final wasOffline = isOffline;
    _simulated = value;
    notifyListeners();
    if (wasOffline && !isOffline) _onBackOnline();
  }

  /// Returns true when the app is online. When offline it shows a message
  /// and returns false, so the caller can stop.
  bool ensureOnline(BuildContext context) {
    if (!isOffline) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection. Please check your connection and try again.'),
      ),
    );
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}