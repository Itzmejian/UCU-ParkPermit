import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/network_store.dart';

/// A thin bar shown at the top when the app is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: NetworkStore.instance,
      builder: (context, child) {
        if (!NetworkStore.instance.isOffline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.textDark,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, size: 16, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline. Actions that need internet are paused.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}