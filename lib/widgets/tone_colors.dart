import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'status_badge.dart';

extension ToneColors on BadgeTone {
  Color get accent => switch (this) {
        BadgeTone.gold => AppColors.gold,
        BadgeTone.green => AppColors.success,
        BadgeTone.red => AppColors.error,
        BadgeTone.gray => AppColors.border,
      };

  Color get tint => switch (this) {
        BadgeTone.gold => AppColors.goldLight,
        BadgeTone.green => AppColors.successLight,
        BadgeTone.red => AppColors.errorLight,
        BadgeTone.gray => AppColors.inputFill,
      };

  Color get ink => switch (this) {
        BadgeTone.gold => AppColors.goldDark,
        BadgeTone.green => AppColors.success,
        BadgeTone.red => AppColors.error,
        BadgeTone.gray => AppColors.navy,
      };
}