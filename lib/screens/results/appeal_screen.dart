import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/doc_picker.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/doc_widgets.dart';
import '../../widgets/status_badge.dart';

class AppealScreen extends StatefulWidget {
  const AppealScreen({super.key});

  @override
  State<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  final ApplicationStore _store = ApplicationStore.instance;
  final MockApplication _app = MockApplication.resolve(PermitStatus.declined);

  final Map<int, PickedDoc> _replacements = <int, PickedDoc>{};
  final Map<int, String> _errors = <int, String>{};
  PickedDoc? _optionalDoc;
  String? _optionalError;
  final TextEditingController _statementCtrl = TextEditingController();
  bool _certified = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _statementCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _statementCtrl.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _replacements.isNotEmpty ||
      _optionalDoc != null ||
      _statementCtrl.text.trim().length >= 10;

  bool get _canSubmit => _certified && _hasContent && !_loading;

  Future<void> _pickReplacement(int index) async {
    final r = await pickDocument();
    if (!mounted || r == null) return;
    setState(() {
      if (r.error != null) {
        _errors[index] = r.error!;
      } else {
        _errors.remove(index);
        _replacements[index] = r.doc!;
      }
    });
  }

  Future<void> _pickOptional() async {
    final r = await pickDocument();
    if (!mounted || r == null) return;
    setState(() {
      if (r.error != null) {
        _optionalError = r.error;
      } else {
        _optionalError = null;
        _optionalDoc = r.doc;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    // TODO: upload the files to Supabase Storage and create the appeal row.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final files = <String>[
      for (final d in _replacements.values) d.name,
      if (_optionalDoc != null) _optionalDoc!.name,
    ];
    final appeal = _store.submitAppeal(
      applicationRef: _app.referenceNo,
      files: files,
      statementLength: _statementCtrl.text.trim().length,
    );
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.appealSubmitted,
      arguments: appeal.ticketNo,
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _banner() {
    final reasons = _app.flagged.map((f) => f.title.toUpperCase()).join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF2B8B8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, size: 20, color: AppColors.error),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Declined permit review',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                _app.referenceNo,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StatusBadge(text: 'REASON: $reasons', tone: BadgeTone.red),
          const SizedBox(height: 8),
          const Text(
            'Please provide clear, valid, uncropped replacement files, or write a statement to ask the Security Office to re-evaluate your application.',
            style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _flaggedCard(int index, FlaggedDocument f) {
    final replaced = _replacements[index];
    final err = _errors[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: replaced != null ? AppColors.success : const Color(0xFFF2B8B8),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                text: replaced != null ? 'REPLACED' : 'REQUIRED FIX',
                tone: replaced != null ? BadgeTone.green : BadgeTone.red,
              ),
              const SizedBox(width: 8),
              const Text(
                'Vehicle verification',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            f.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
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
                  'Officer note',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  f.remark,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (replaced == null)
            DocEmptyPicker(
              label: 'Upload clear replacement',
              onTap: () => _pickReplacement(index),
            )
          else
            DocFileRow(
              doc: replaced,
              onReplace: () => _pickReplacement(index),
              onRemove: () => setState(() => _replacements.remove(index)),
            ),
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                err,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _optionalCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              StatusBadge(text: 'OPTIONAL', tone: BadgeTone.gray),
              SizedBox(width: 8),
              Text(
                'UCU ID',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The ID you already submitted is kept. Replace it only if your details changed.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (_optionalDoc == null)
            DocEmptyPicker(
              label: 'Tap to choose a new ID (optional)',
              onTap: _pickOptional,
            )
          else
            DocFileRow(
              doc: _optionalDoc!,
              onReplace: _pickOptional,
              onRemove: () => setState(() => _optionalDoc = null),
            ),
          if (_optionalError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _optionalError!,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _app.flagged.length - _replacements.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Resubmit & Appeal',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            Text(
              'UCU SECURITY DIVISION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.goldDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.permitRequirements),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _banner(),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Flagged documents to update',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  StatusBadge(
                    text: pending > 0 ? '$pending ACTION NEEDED' : 'ALL REPLACED',
                    tone: pending > 0 ? BadgeTone.red : BadgeTone.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < _app.flagged.length; i++)
                _flaggedCard(i, _app.flagged[i]),
              _optionalCard(),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Statement of Appeal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  Text(
                    'OPTIONAL',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _statementCtrl,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText:
                      'Explain anything the officer should know, such as why the first file was unclear.',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.inputFill,
                  contentPadding: const EdgeInsets.all(14),
                  border: _border(AppColors.border),
                  enabledBorder: _border(AppColors.border),
                  focusedBorder: _border(AppColors.navy, 1.8),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _certified = !_certified),
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
                          value: _certified,
                          activeColor: AppColors.navy,
                          onChanged: (v) => setState(() => _certified = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'I certify that all resubmitted documents and statements are authentic and valid under university safety guidelines.',
                          style: TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Submit Resubmission & Appeal',
                showArrow: true,
                isLoading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
              if (!_canSubmit && !_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Upload at least one replacement file or write a short statement, then tick the certification.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
                  ),
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel & Return',
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