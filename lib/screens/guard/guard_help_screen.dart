import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/office_info.dart';
import '../../services/guard_service.dart';

const Color _navyDark = Color(0xFF0F2552);

const List<(String, String)> _faqs = [
  (
    'The camera does not open or the screen is black.',
    'Tap "Allow camera" on the scanner. If it still does not work, open your phone Settings, then Apps, UCU ParkPermit, Permissions, and allow Camera. While waiting, type the permit number or plate in "Can\'t scan the QR?".',
  ),
  (
    'The QR code will not scan.',
    'Hold the phone 15 to 30 cm from the sticker, avoid glare from the sun or lights, and wipe the sticker if it is dirty. If it still fails, type the permit number or the plate number.',
  ),
  (
    'What does NOT FOUND mean?',
    'No permit matches the sticker or number. The sticker may be fake, an old sticker that was replaced, or the number was mistyped. Check the typing first. If it is still not found, do not let the vehicle park in permit zones and ask the driver to go to the Security Office.',
  ),
  (
    'What does PERMIT EXPIRED mean?',
    'The permit is no longer valid. Direct the driver to the visitor parking bays and remind them to renew in the UCU ParkPermit app.',
  ),
  (
    'What does STICKER NOT CLAIMED mean?',
    'The permit was approved but the sticker was not released yet, so the sticker shown may be a copy. Ask the driver to claim the real sticker at the Security Office.',
  ),
  (
    'The plate on the screen does not match the vehicle.',
    'Do not allow the vehicle to park in permit zones. Take note of the plate and send a message to the Security Office below.',
  ),
  (
    'There is no internet at the gate.',
    'Checks need internet. Until it is back, check the sticker and the plate by hand and write them in the gate logbook.',
  ),
  (
    'I forgot my password or cannot log in.',
    'Guard accounts are managed by the Security Office. Go to the office or ask the admin to reset your password. Do not share your account with other guards.',
  ),
  (
    'I lost my phone or got a new one.',
    'Tell the Security Office right away so they can secure your account. On the new phone, install the app and log in again.',
  ),
  (
    'Who can see my scans?',
    'Every check is recorded with your account and can be seen by the Security Office admin. The details you see are personal data protected by the Data Privacy Act of 2012 (RA 10173). Do not take screenshots or share them.',
  ),
];

const List<String> _topics = ['Account', 'Scanner problem', 'Sticker issue', 'Other'];

class GuardHelpScreen extends StatefulWidget {
  const GuardHelpScreen({super.key, this.loggedIn = true});

  /// Sending messages needs a guard who is logged in.
  final bool loggedIn;

  @override
  State<GuardHelpScreen> createState() => _GuardHelpScreenState();
}

class _GuardHelpScreenState extends State<GuardHelpScreen> {
  String _topic = _topics.first;
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _sending = false;
  bool _loadingMessages = false;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.loggedIn) _loadMessages();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _loadingMessages = true);
    try {
      final rows = await GuardService.myMessages();
      if (!mounted) return;
      setState(() => _messages = rows);
    } catch (_) {}
    if (mounted) setState(() => _loadingMessages = false);
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final subject = _subject.text.trim();
    final message = _message.text.trim();
    if (subject.length < 5 || message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a subject (at least 5 characters) and a message (at least 10).')),
      );
      return;
    }
    setState(() => _sending = true);
    final r = await GuardService.sendMessage(_topic, subject, message);
    if (!mounted) return;
    setState(() => _sending = false);
    if (r.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.error!)));
      return;
    }
    _subject.clear();
    _message.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent. Ticket ${r.ticket}. The reply will appear under My messages.')),
    );
    _loadMessages();
  }

  InputDecoration _deco(String hint) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: b(AppColors.border),
      enabledBorder: b(AppColors.border),
      focusedBorder: b(AppColors.navy, 1.6),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _caption(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.goldDark),
      ),
    );
  }

  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, _navyDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 22),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                child: const Icon(Icons.support_agent, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guard Help & Support',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    Text(
                      'Answers and help from the Security Office',
                      style: TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contact() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.apartment, color: AppColors.navy),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  kOfficeName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: AppColors.textHint),
              SizedBox(width: 8),
              Text(kOfficeLocation, style: TextStyle(color: AppColors.textDark)),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_outlined, size: 18, color: AppColors.textHint),
              SizedBox(width: 8),
              Text(kOfficeHours, style: TextStyle(color: AppColors.textDark)),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'For emergencies, use your radio or go to the office right away.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _faqList() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            for (var i = 0; i < _faqs.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              ExpansionTile(
                iconColor: AppColors.navy,
                collapsedIconColor: AppColors.textHint,
                title: Text(
                  _faqs[i].$1,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(
                    _faqs[i].$2,
                    style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sendCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send a message',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'The Security Office will reply here.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _topics)
                ChoiceChip(
                  label: Text(t),
                  selected: _topic == t,
                  selectedColor: AppColors.goldLight,
                  onSelected: (_) => setState(() => _topic = t),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: _deco('Subject'),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _message,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: _deco('Message'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Send to Security Office', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String s) {
    final (text, fg, bg) = switch (s) {
      'answered' => ('ANSWERED', AppColors.success, AppColors.successLight),
      'closed' => ('CLOSED', AppColors.textMuted, AppColors.inputFill),
      _ => ('WAITING', AppColors.goldDark, AppColors.goldLight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: fg)),
    );
  }

  Widget _messageCard(Map<String, dynamic> m) {
    final reply = (m['reply'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (m['ticket_no'] ?? '').toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                ),
                _statusPill((m['status'] ?? '').toString()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              (m['subject'] ?? '').toString(),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 2),
            Text((m['message'] ?? '').toString(), style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            if (reply.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reply from the Security Office',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                    const SizedBox(height: 4),
                    Text(reply, style: const TextStyle(fontSize: 13.5, color: AppColors.textDark)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _caption('CONTACT THE SECURITY OFFICE'),
                  _contact(),
                  const SizedBox(height: 18),
                  _caption('FREQUENTLY ASKED QUESTIONS'),
                  _faqList(),
                  if (widget.loggedIn) ...[
                    const SizedBox(height: 18),
                    _caption('NEED MORE HELP?'),
                    _sendCard(),
                    const SizedBox(height: 18),
                    _caption('MY MESSAGES'),
                    if (_loadingMessages)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('No messages yet.', style: TextStyle(color: AppColors.textMuted)),
                      )
                    else
                      for (final m in _messages) _messageCard(m),
                  ] else ...[
                    const SizedBox(height: 18),
                    _card(
                      child: const Text(
                        'Log in as a guard to send a message to the Security Office.',
                        style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}