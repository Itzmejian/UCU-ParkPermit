import 'package:flutter/material.dart';
import 'core/app_routes.dart';
import 'core/app_theme.dart';

void main() {
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