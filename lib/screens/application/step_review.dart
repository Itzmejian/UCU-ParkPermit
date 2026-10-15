import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/application_draft.dart';
import '../../widgets/step_footer.dart';

class StepReview extends StatefulWidget {
  const StepReview({
    super.key,
    required this.draft,
    required this.submitting,
    required this.onSubmit,
    required this.onBack,
    required this.onSaveDraft,
    required this.onEdit,
  });

  final ApplicationDraft draft;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final ValueChanged<int> onEdit;

  @override
  State<StepReview> createState() => _StepReviewState();
}

class _StepReviewState extends State<StepReview> {
  ApplicationDraft get d => widget.draft;

  bool get _canSubmit =>
      d.declarationAccepted && (!d.isMotorcycle || d.helmetAccepted);

  Widget _section(String title, int step, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => widget.onEdit(step),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 15, color: AppColors.navy),
                    SizedBox(width: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docRow(String label, PickedDoc? doc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            doc == null ? Icons.error_outline : Icons.check_circle,
            size: 18,
            color: doc == null ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  doc == null ? 'Missing' : '${doc.name}  (${doc.sizeLabel})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: AppColors.navy,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review your application',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check everything before you submit. You can edit any part.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          _section('Vehicle type', 0, [
            _row('Type', d.vehicleType?.label ?? ''),
          ]),
          _section('Vehicle details', 1, [
            _row('Plate Number', d.plateDisplay, mono: true),
            _row('Make / Model', d.makeModel.trim()),
            _row('Color', d.color.trim()),
            _row('Model Year', d.modelYear.trim()),
          ]),
          _section('Documents', 2, [
            _docRow("Driver's License", d.license),
            _docRow('Vehicle OR/CR', d.orcr),
            _docRow('UCU ID', d.ucuId),
          ]),
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline, size: 18, color: AppColors.navy),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your profile details (ID number and contact number) are attached automatically.',
                    style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _checkTile(
                  value: d.declarationAccepted,
                  onChanged: (v) => setState(() => d.declarationAccepted = v),
                  text:
                      'I confirm that all details and documents I submitted are true and belong to me and my vehicle. I agree to follow the UCU Safety and Campus Security guidelines. My documents are handled under the Data Privacy Act (RA 10173).',
                ),
                if (d.isMotorcycle)
                  _checkTile(
                    value: d.helmetAccepted,
                    onChanged: (v) => setState(() => d.helmetAccepted = v),
                    text: 'I understand the helmet safety requirement for 2-wheel vehicles.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          StepFooter(
            primaryLabel: 'Submit Application',
            showArrow: false,
            isLoading: widget.submitting,
            onPrimary: _canSubmit ? widget.onSubmit : null,
            secondaryLabel: 'Back to Documents',
            onSecondary: widget.onBack,
            onSaveDraft: widget.onSaveDraft,
          ),
        ],
      ),
    );
  }
}