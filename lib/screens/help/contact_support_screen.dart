import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/date_format.dart';
import '../../core/validators.dart';
import '../../models/network_store.dart';
import '../../models/notification_store.dart';
import '../../models/support_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/option_sheet.dart';
import '../../widgets/status_badge.dart';

const List<String> _topics = [
  'Permit application',
  'Documents',
  'Sticker',
  'Vehicles',
  'Account',
  'Other',
];

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _topic = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _message = TextEditingController();
  bool _loading = false;
  SupportTicket? _sent;

  @override
  void dispose() {
    _topic.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _pickTopic() async {
    FocusScope.of(context).unfocus();
    final choice = await showOptionSheet(
      context,
      title: 'What is it about?',
      options: _topics,
      selected: _topic.text,
    );
    if (choice != null) setState(() => _topic.text = choice);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    // TODO: send the inquiry to Supabase.
    if (DataService.live) {
      final r = await DataService.createSupportTicket(
        topic: _topic.text.trim(),
        subject: _subject.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      if (!r.ok) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.error ?? 'Could not send your message.')),
        );
        return;
      }
      await SupportStore.instance.loadRemote();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = SupportTicket(
          ticketNo: r.value ?? '-',
          category: _topic.text.trim(),
          subject: _subject.text.trim(),
          message: _message.text.trim(),
          createdAt: DateTime.now(),
        );
      });
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final ticket = SupportStore.instance.create(
      category: _topic.text.trim(),
      subject: _subject.text.trim(),
      message: _message.text.trim(),
    );
    NotificationStore.instance.add(
      kind: NotifKind.account,
      title: 'Inquiry received',
      body: 'Ticket ${ticket.ticketNo} was sent to the Campus Security Office.',
    );
    setState(() {
      _loading = false;
      _sent = ticket;
    });
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _sentView(SupportTicket t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: IconBadge(
              icon: Icons.mark_email_read_outlined,
              background: AppColors.successLight,
              foreground: AppColors.success,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Inquiry sent',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The Campus Security Office received your message. We will notify you in the app when there is a reply.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.tag, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                const Text(
                  'Ticket',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const Spacer(),
                Text(
                  t.ticketNo,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                    fontFamily: 'monospace',
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.navy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: t.ticketNo));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket number copied')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Back to Help',
            showArrow: true,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              setState(() {
                _sent = null;
                _topic.clear();
                _subject.clear();
                _message.clear();
              });
            },
            child: const Text(
              'Send another message',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recent() {
    final tickets = SupportStore.instance.tickets.take(3).toList();
    if (tickets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR RECENT INQUIRIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.goldDark,
              ),
            ),
            const SizedBox(height: 8),
            for (final t in tickets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${t.ticketNo}  \u2022  ${formatLongDate(t.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    const StatusBadge(text: 'SENT', tone: BadgeTone.gold),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Send us a message',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your question goes to the Campus Security Office. Check Help & Support first, because your answer may already be there.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Topic',
              hint: 'What is it about?',
              icon: Icons.label_outline,
              controller: _topic,
              isRequired: true,
              readOnly: true,
              onTap: _pickTopic,
              trailingIcon: Icons.keyboard_arrow_down_rounded,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Please choose a topic' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Subject',
              hint: 'e.g., My sticker has not arrived',
              icon: Icons.subject,
              controller: _subject,
              isRequired: true,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final r = Validators.required(v, 'Subject');
                if (r != null) return r;
                if (v!.trim().length < 5) return 'Please write at least 5 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text.rich(
              TextSpan(
                text: 'Message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                children: [
                  TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _message,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Describe your question or problem.',
                hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.inputFill,
                contentPadding: const EdgeInsets.all(14),
                border: _border(AppColors.border),
                enabledBorder: _border(AppColors.border),
                focusedBorder: _border(AppColors.navy, 1.8),
                errorBorder: _border(AppColors.error),
                focusedErrorBorder: _border(AppColors.error, 1.8),
              ),
              validator: (v) {
                final r = Validators.required(v, 'Message');
                if (r != null) return r;
                if (v!.trim().length < 10) return 'Please write at least 10 characters';
                return null;
              },
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppColors.navy),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Never include your password or verification code in a message.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Send Message',
              showArrow: true,
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
              ),
            ),
            AnimatedBuilder(
              animation: SupportStore.instance,
              builder: (context, child) => _recent(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contact Support',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(child: sent != null ? _sentView(sent) : _form()),
    );
  }
}