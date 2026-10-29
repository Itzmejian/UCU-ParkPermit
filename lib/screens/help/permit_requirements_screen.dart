import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/app_routes.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../home/home_cards.dart';

class PermitRequirementsScreen extends StatelessWidget {
  const PermitRequirementsScreen({super.key});

  Widget _caption(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.goldDark,
      ),
    );
  }

  Widget _docCard(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _point(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 17, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permit Requirements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'What you need to apply',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'UCU students, instructors and staff can apply for a campus parking permit.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _caption('DOCUMENTS YOU NEED'),
                  const SizedBox(height: 6),
                  _docCard(
                    Icons.badge_outlined,
                    "Driver's License",
                    'A valid license. Your name and license number must be readable. Expired licenses are declined.',
                  ),
                  _docCard(
                    Icons.description_outlined,
                    'Vehicle OR/CR',
                    'The Official Receipt and Certificate of Registration. The plate number must be readable and match your application.',
                  ),
                  _docCard(
                    Icons.credit_card,
                    'UCU ID',
                    'Your current UCU student or employee ID.',
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _point('PDF, JPG or PNG files, up to $kMaxUploadMb MB each.'),
                  _point('Clear, uncropped photos or scans. Blurry files will be declined.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const HowToCard(),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _caption('GOOD TO KNOW'),
                  const SizedBox(height: 6),
                  _point('You can register up to $kMaxVehicles vehicles. A pending application counts as one.'),
                  _point('The review takes about 24 to 48 business hours.'),
                  _point('If your application is declined, you have 7 days to appeal.'),
                  _point('Your permit number is printed on the sticker. The guard checks the sticker at the gate.'),
                  _point('Renew your permit before it expires so you can keep parking on campus.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Apply for Permit',
              showArrow: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.apply),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Help & Support',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.help),
            ),
          ],
        ),
      ),
    );
  }
}