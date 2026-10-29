import 'package:flutter/material.dart';

/// Tracks whether the app has internet. For now it is only a testing switch.
/// Real detection is added when the app is connected to Supabase.
class NetworkStore extends ChangeNotifier {
  NetworkStore._();

  static final NetworkStore instance = NetworkStore._();

  bool _offline = false;

  bool get isOffline => _offline;

  void setOffline(bool value) {
    if (_offline == value) return;
    _offline = value;
    notifyListeners();
  }

  /// Returns true when the app is online. When offline it shows a message
  /// and returns false, so the caller can stop.
  bool ensureOnline(BuildContext context) {
    if (!_offline) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection. Please check your connection and try again.'),
      ),
    );
    return false;
  }
}