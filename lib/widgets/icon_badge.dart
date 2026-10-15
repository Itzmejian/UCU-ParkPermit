import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 76,
    this.background = AppColors.inputFill,
    this.foreground = AppColors.navy,
  });

  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.48, color: foreground),
    );
  }
}