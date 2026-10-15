import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SecurityFooter extends StatelessWidget {
  const SecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.inputFill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 14, color: AppColors.navy),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                'URDANETA CITY UNIVERSITY SECURITY OFFICE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}