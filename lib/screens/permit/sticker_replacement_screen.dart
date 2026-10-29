import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/network_store.dart';
import '../../core/app_colors.dart';
import '../../models/application_store.dart';
import '../../widgets/app_buttons.dart';

class StickerReplacementScreen extends StatefulWidget {
  const StickerReplacementScreen({super.key});

  @override
  State<StickerReplacementScreen> createState() =>
      _StickerReplacementScreenState();
}

class _StickerReplacementScreenState extends State<StickerReplacementScreen> {
  static const String _reasonOther = 'Other';

  final TextEditingController _detailsCtrl = TextEditingController();
  String? _reason;
  bool _confirmed = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _detailsCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_reason == null || !_confirmed || _loading) return false;
    if (_reason == _reasonOther && _detailsCtrl.text.trim().length < 10) {
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    // TODO: send the request to Supabase.
    if (DataService.live) {
      final r = await DataService.requestReplacement(
        reason: _reason!,
        details: _detailsCtrl.text.trim(),
      );
      if (!mounted) return;
      if (!r.ok) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.error ?? 'Could not send your request.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Replacement requested. We will notify you.')),
      );
      Navigator.pop(context);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    ApplicationStore.instance.requestReplacement(
      reason: _reason!,
      details: _detailsCtrl.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Replacement requested. We will notify you.')),
    );
    Navigator.pop(context);
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _reasonTile(String title, String subtitle, IconData icon) {
    final selected = _reason == title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? AppColors.inputFill : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _reason = title),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppColors.navy : AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsDetails = _reason == _reasonOther;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sticker Replacement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Why do you need a new sticker?',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us what happened to your current sticker. The Security Office will review your request.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              _reasonTile('Lost', 'I cannot find my sticker', Icons.search_off_outlined),
              _reasonTile('Damaged or unreadable', 'It is torn, faded or peeling', Icons.broken_image_outlined),
              _reasonTile(_reasonOther, 'Something else happened', Icons.help_outline),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'More details',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  children: [
                    TextSpan(
                      text: needsDetails ? ' *' : ' (optional)',
                      style: TextStyle(
                        color: needsDetails ? AppColors.error : AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _detailsCtrl,
                maxLines: 4,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Add anything the officer should know.',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.all(14),
                  border: _border(AppColors.border),
                  enabledBorder: _border(AppColors.border),
                  focusedBorder: _border(AppColors.navy, 1.8),
                ),
              ),
              if (needsDetails && _detailsCtrl.text.trim().length < 10)
                const Padding(
                  padding: EdgeInsets.only(top: 2, bottom: 6),
                  child: Text(
                    'Please write at least 10 characters.',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _confirmed = !_confirmed),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _confirmed,
                          activeColor: AppColors.navy,
                          onChanged: (v) => setState(() => _confirmed = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I understand the Security Office will review my request before a new sticker is issued.',
                          style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Submit Request',
                showArrow: true,
                isLoading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}