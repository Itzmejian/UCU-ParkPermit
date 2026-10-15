import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'ucu_logo.dart';

/// Top bar for result screens: logo, name and a close button.
class NoticeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoticeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16,
      title: const Row(
        children: [
          UcuLogo(size: 30),
          SizedBox(width: 10),
          Text(
            'UCU ParkPermit',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}