import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Shows assets/images/ucu_logo.png. Until you add that file,
/// a simple placeholder icon is shown instead.
class UcuLogo extends StatelessWidget {
  const UcuLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/ucu_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _FallbackLogo(size: size),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.local_parking_rounded,
        color: AppColors.gold,
        size: size * 0.58,
      ),
    );
  }
}