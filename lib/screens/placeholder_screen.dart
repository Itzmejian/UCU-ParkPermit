import 'package:flutter/material.dart';
import '../widgets/state_views.dart';

/// Shown if the app is sent to a page that does not exist.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ErrorState(
          icon: Icons.explore_off_outlined,
          title: 'Page not found',
          message: 'We could not find "$routeName".',
          retryLabel: 'Go Back',
          onRetry: () => Navigator.maybePop(context),
        ),
      ),
    );
  }
}