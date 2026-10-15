import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum BadgeTone { gold, green, red, gray }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.text, this.tone = BadgeTone.gold});

  final String text;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    switch (tone) {
      case BadgeTone.gold:
        bg = AppColors.goldLight;
        fg = AppColors.goldDark;
        border = AppColors.gold;
        break;
      case BadgeTone.green:
        bg = AppColors.successLight;
        fg = const Color(0xFF14532D);
        border = AppColors.success;
        break;
      case BadgeTone.red:
        bg = AppColors.errorLight;
        fg = const Color(0xFF7F1D1D);
        border = AppColors.error;
        break;
      case BadgeTone.gray:
        bg = AppColors.inputFill;
        fg = AppColors.textMuted;
        border = AppColors.border;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}