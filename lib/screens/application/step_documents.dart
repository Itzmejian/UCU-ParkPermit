import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../models/application_draft.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/step_footer.dart';

enum _Slot { license, orcr, ucuId }

class StepDocuments extends StatefulWidget {
  const StepDocuments({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
    required this.onSaveDraft,
  });

  final ApplicationDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;

  @override
  State<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends State<StepDocuments> {
  final Map<_Slot, String> _errors = <_Slot, String>{};

  PickedDoc? _docOf(_Slot s) {
    return switch (s) {
      _Slot.license => widget.draft.license,
      _Slot.orcr => widget.draft.orcr,
      _Slot.ucuId => widget.draft.ucuId,
    };
  }

  void _setDoc(_Slot s, PickedDoc? doc) {
    switch (s) {
      case _Slot.license:
        widget.draft.license = doc;
        break;
      case _Slot.orcr:
        widget.draft.orcr = doc;
        break;
      case _Slot.ucuId:
        widget.draft.ucuId = doc;
        break;
    }
  }

  String _title(_Slot s) {
    return switch (s) {
      _Slot.license => "Driver's License",
      _Slot.orcr => 'Vehicle OR/CR',
      _Slot.ucuId => 'UCU ID',
    };
  }

  String _hint(_Slot s) {
    return switch (s) {
      _Slot.license => 'Front side. Your name and license number must be readable.',
      _Slot.orcr => 'Official Receipt and Certificate of Registration. The plate number must be readable.',
      _Slot.ucuId => 'Your current UCU student or employee ID.',
    };
  }

  Future<void> _pick(_Slot slot) async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedExtensions,
        withData: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _errors[slot] = 'Could not open the file picker. Please try again.');
      return;
    }
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final f = result.files.first;
    final ext = (f.extension ?? '').toLowerCase();
    if (!kAllowedExtensions.contains(ext)) {
      setState(() => _errors[slot] = 'Only PDF, JPG or PNG files are allowed.');
      return;
    }
    if (f.size > kMaxUploadBytes) {
      final mb = (f.size / (1024 * 1024)).toStringAsFixed(1);
      setState(() => _errors[slot] = 'This file is $mb MB. The maximum is $kMaxUploadMb MB.');
      return;
    }
    setState(() {
      _errors.remove(slot);
      _setDoc(slot, PickedDoc(name: f.name, sizeBytes: f.size, bytes: f.bytes));
    });
  }

  void _remove(_Slot slot) {
    setState(() {
      _errors.remove(slot);
      _setDoc(slot, null);
    });
  }

  int get _attached {
    int n = 0;
    for (final s in _Slot.values) {
      if (_docOf(s) != null) n++;
    }
    return n;
  }

  Widget _card(_Slot slot) {
    final doc = _docOf(slot);
    final err = _errors[slot];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: err != null ? AppColors.error : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: _title(slot),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                    children: const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ),
              StatusBadge(
                text: doc == null ? 'REQUIRED' : 'UPLOADED',
                tone: doc == null ? BadgeTone.gold : BadgeTone.green,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _hint(slot),
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (doc == null)
            _EmptyPicker(onTap: () => _pick(slot))
          else
            _FileRow(
              doc: doc,
              onReplace: () => _pick(slot),
              onRemove: () => _remove(slot),
            ),
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      err,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _attached;
    final all = count == _Slot.values.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload required documents',
            style: TextStyle(
              fontSize: 25,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload clear photos or scans. PDF, JPG or PNG, up to $kMaxUploadMb MB each.',
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          for (final s in _Slot.values) _card(s),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 18, color: AppColors.goldDark),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For quick approval: make sure all text, plate numbers and names are sharp and readable. Expired or blurry documents will be declined.',
                    style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                all ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: all ? AppColors.success : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                all
                    ? 'All 3 required documents attached'
                    : '$count of 3 required documents attached',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: all ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StepFooter(
            primaryLabel: 'Next Step',
            onPrimary: all ? widget.onNext : null,
            secondaryLabel: 'Back to Vehicle Details',
            onSecondary: widget.onBack,
            onSaveDraft: widget.onSaveDraft,
          ),
        ],
      ),
    );
  }
}

class _EmptyPicker extends StatelessWidget {
  const _EmptyPicker({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.inputFill,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              const Icon(Icons.cloud_upload_outlined, size: 30, color: AppColors.navy),
              const SizedBox(height: 6),
              const Text(
                'Tap to choose a file',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PDF, JPG or PNG, up to $kMaxUploadMb MB',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.doc,
    required this.onReplace,
    required this.onRemove,
  });

  final PickedDoc doc;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              doc.isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.sizeLabel}  \u2022  ${doc.extension.toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Replace',
            onPressed: onReplace,
            icon: const Icon(Icons.sync_alt, size: 20, color: AppColors.navy),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}