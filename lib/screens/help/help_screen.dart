import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/office_info.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';
import '../home/home_cards.dart';

class _Faq {
  const _Faq(this.category, this.question, this.answer);

  final String category;
  final String question;
  final String answer;
}

const List<String> _categories = [
  'All',
  'Permits',
  'Documents',
  'Sticker',
  'Vehicles',
  'Account',
];

const List<_Faq> _faqs = [
  _Faq(
    'Permits',
    'How do I apply for a parking permit?',
    'Go to Home and tap Apply for Permit. Choose your vehicle type, enter the vehicle details, upload your documents, then review and submit. You can save a draft at any step.',
  ),
  _Faq(
    'Permits',
    'How long does the review take?',
    'The Security Office usually reviews an application within 24 to 48 office hours. You will get a notification in the bell when something changes.',
  ),
  _Faq(
    'Permits',
    'What if my application is declined?',
    'Open the declined notice and read the remarks for each document. You have 7 days to file an appeal: replace the flagged documents, add an optional statement, and submit.',
  ),
  _Faq(
    'Permits',
    'Can I register more than one vehicle?',
    'Yes, up to 2 vehicles. A pending application counts as one. Add another vehicle from the Vehicles tab.',
  ),
  _Faq(
    'Permits',
    'How do I renew my permit?',
    'When your permit is expiring soon or has expired, tap Renew Permit on the Home screen. Confirm that your vehicle is the same, upload your OR/CR and driver\'s license, and submit.',
  ),
  _Faq(
    'Documents',
    'What documents do I need?',
    'Your driver\'s license, your vehicle OR/CR, and your UCU ID. Files must be PDF, JPG or PNG, up to 5 MB each, and clear.',
  ),
  _Faq(
    'Documents',
    'Why might my documents be declined?',
    'Common reasons are blurry or cropped files, an unreadable plate number, or an expired license. The officer writes the reason for each document so you can upload a better copy.',
  ),
  _Faq(
    'Sticker',
    'How does the guard check my permit?',
    'The guard looks at the permit sticker on your vehicle and its permit number. You do not need to show anything on your phone.',
  ),
  _Faq(
    'Sticker',
    'Where do I get my sticker?',
    'After your permit is approved, we notify you when the sticker is ready. Claim it at the Campus Security Office. The Sticker Pickup screen shows the details.',
  ),
  _Faq(
    'Sticker',
    'My sticker was lost or damaged.',
    'Open Permit Details and tap Request Sticker Replacement. Choose a reason and send the request. The Security Office will review it.',
  ),
  _Faq(
    'Vehicles',
    'How do I update my vehicle details?',
    'Go to Vehicles, open the vehicle, and tap Request Update. A new plate number needs verification (about 24 hours) and a new OR/CR. Changes to the make or model, color and year are saved right away.',
  ),
  _Faq(
    'Vehicles',
    'How do I remove a vehicle?',
    'Open the vehicle in the Vehicles tab and tap Remove Vehicle. This frees one slot. To use that vehicle again you need to apply again.',
  ),
  _Faq(
    'Account',
    'I forgot my password.',
    'On the Log In screen, tap Forgot password and enter your email. We send a reset link so you can set a new password.',
  ),
  _Faq(
    'Account',
    'I did not get the verification code.',
    'Check your spam folder and make sure your email is correct. You can ask for a new code after 30 seconds, or go back and use a different email.',
  ),
  _Faq(
    'Account',
    'How do I change my profile details?',
    'Go to Profile and tap Edit Profile. Your email, user type, ID number and birthday cannot be changed in the app. Contact the Campus Security Office if they are wrong.',
  ),
];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _category = 'All';
  _Faq? _selected;

  List<_Faq> get _filtered =>
      _faqs.where((f) => _category == 'All' || f.category == _category).toList();

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _chip(String label) {
    final selected = _category == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.navy : AppColors.inputFill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() {
            _category = label;
            if (_selected != null && label != 'All' && _selected!.category != label) {
              _selected = null;
            }
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The FAQ as one drop-down list: choose a question, the answer shows below.
  Widget _faqPicker(List<_Faq> results) {
    final value = results.contains(_selected) ? _selected : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            prefixIcon: const Icon(Icons.help_outline, color: AppColors.navy),
            contentPadding: const EdgeInsets.fromLTRB(0, 4, 8, 4),
            border: _border(AppColors.border),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.navy, 1.8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_Faq>(
              value: value,
              isExpanded: true,
              itemHeight: null,
              menuMaxHeight: 420,
              borderRadius: BorderRadius.circular(14),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.navy),
              hint: const Text(
                'Choose a question',
                style: TextStyle(fontSize: 14.5, color: AppColors.textHint),
              ),
              selectedItemBuilder: (context) => [
                for (final f in results)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      f.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
              ],
              items: [
                for (final f in results)
                  DropdownMenuItem<_Faq>(
                    value: f,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        f.question,
                        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                      ),
                    ),
                  ),
              ],
              onChanged: (f) => setState(() => _selected = f),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: value == null
              ? Container(
                  key: const ValueKey('none'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app_outlined, color: AppColors.textHint),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pick a question from the list to see the answer.',
                          style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  key: ValueKey(value.question),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.navy.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value.question,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value.answer,
                        style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(text: value.category.toUpperCase(), tone: BadgeTone.gray),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.support_agent_outlined, size: 28, color: AppColors.navy),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Find answers about your parking permit, or send a message to the Campus Security Office.',
                          style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const HowToCard(),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SUPPORT OFFICE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.apartment_outlined, size: 20, color: AppColors.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kOfficeName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.meeting_room_outlined, size: 20, color: AppColors.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kOfficeLocation,
                          style: TextStyle(fontSize: 14, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppColors.navy),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kOfficeHours,
                          style: TextStyle(fontSize: 14, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: 'Contact Support',
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.contactSupport),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Frequently asked questions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                StatusBadge(
                  text: '${results.length} ${results.length == 1 ? 'TOPIC' : 'TOPICS'}',
                  tone: BadgeTone.gray,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final c in _categories) _chip(c)]),
            ),
            const SizedBox(height: 12),
            _faqPicker(results),
            const SizedBox(height: 10),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.headset_mic_outlined, size: 20, color: AppColors.goldDark),
                      SizedBox(width: 8),
                      Text(
                        'Still need help?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Send your question straight to the Campus Security Office.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Contact Support',
                    showArrow: true,
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.contactSupport),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}