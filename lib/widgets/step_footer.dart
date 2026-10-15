import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'app_buttons.dart';

class StepFooter extends StatelessWidget {
  const StepFooter({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.showArrow = true,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryIsBack = true,
    this.onSaveDraft,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool showArrow;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryIsBack;
  final VoidCallback? onSaveDraft;

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.navy,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(
          label: primaryLabel,
          showArrow: showArrow,
          isLoading: isLoading,
          onPressed: onPrimary,
        ),
        if (secondaryLabel != null)
          secondaryIsBack
              ? TextButton.icon(
                  onPressed: onSecondary,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: Text(secondaryLabel!, style: linkStyle),
                )
              : TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!, style: linkStyle),
                ),
        if (onSaveDraft != null)
          TextButton(
            onPressed: onSaveDraft,
            child: const Text(
              'Save as Draft',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 13, color: AppColors.textHint),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'UCU Safety & Campus Security Enforcement Office',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}