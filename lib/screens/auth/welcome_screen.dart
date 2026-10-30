import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/ucu_logo.dart';
import '../guard/guard_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Security guard',
            icon: const Icon(Icons.info_outline, color: AppColors.navy),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuardLoginScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        const UcuLogo(size: 120),
                        const SizedBox(height: 28),
                        const Text(
                          'URDANETA CITY UNIVERSITY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ParkPermit',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Digital vehicle registration and\ncampus parking access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const Spacer(flex: 4),
                        PrimaryButton(
                          label: 'Log In',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.login),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Create an account',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.register),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Need assistance? Contact Campus Security & Safety Office',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'v1.0 \u2022 UCU Security Office',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}