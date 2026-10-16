import 'package:flutter/material.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';
import 'models/notification_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationStore.instance.ensureStarted();
  runApp(const ParkPermitApp());
}

class ParkPermitApp extends StatelessWidget {
  const ParkPermitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCU ParkPermit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}