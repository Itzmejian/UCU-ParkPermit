import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/network_store.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/doc_picker.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/doc_widgets.dart';
import '../../widgets/status_badge.dart';

class RenewalScreen extends StatefulWidget {
  const RenewalScreen({super.key});

  @override
  State<RenewalScreen> createState() => _RenewalScreenState();
}

class _RenewalScreenState extends State<RenewalScreen> {
  final ApplicationStore _store = ApplicationStore.instance;

  PickedDoc? _orcr;
  PickedDoc? _license;
  PickedDoc? _ucuId;
  final Map<String, String> _errors = <String, String>{};
  bool _unchanged = false;
  bool _declared = false;
  bool _loading = false;

  bool get _canSubmit =>
      _unchanged && _declared && _orcr != null && _license != null && !_loading;

  Future<void> _pick(String key, ValueChanged<PickedDoc> onPicked) async {
    final r = await pickDocument();
    if (!mounted || r == null) return;
    setState(() {
      if (r.error != null) {
        _errors[key] = r.error!;
      } else {
        _errors.remove(key);
        onPicked(r.doc!);
      }
    });
  }

  Future<void> _submit() async {
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    // TODO: upload the files to Supabase Storage and create the renewal.
    if (DataService.live) {
      final r = await DataService.submitRenewal(
        orcr: _orcr!,
        license: _license!,
        ucuId: _ucuId,
      );
      if (!mounted) return;
      if (!r.ok) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.error ?? 'Could not submit your renewal.')),
        );
        return;
      }
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.applicationSubmitted,
        arguments: r.value,
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final app = MockApplication.resolve(_store.status);
    final base = _store.submitted?.draft;
    final d = ApplicationDraft()
      ..vehicleType = base?.vehicleType ?? VehicleType.fourWheel
      ..plate = base?.plate ?? app.plate
      ..makeModel = base?.makeModel ?? app.vehicleName
      ..color = base?.color ?? ''
      ..modelYear = base?.modelYear ?? ''
      ..license = _license
      ..orcr = _orcr
      ..ucuId = _ucuId ?? base?.ucuId
      ..declarationAccepted = true;

    final sub = _store.submitRenewal(d);
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.applicationSubmitted,
      arguments: sub.referenceNo,
    );
  }

  Widget _docCard({
    required String title,
    required String hint,
    required bool isRequired,
    required PickedDoc? doc,
    required String errorKey,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final err = _errors[errorKey];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              StatusBadge(
                text: doc != null ? 'UPLOADED' : (isRequired ? 'REQUIRED' : 'OPTIONAL'),
                tone: doc != null
                    ? BadgeTone.green
                    : (isRequired ? BadgeTone.gold : BadgeTone.gray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (doc == null)
            DocEmptyPicker(onTap: onPick)
          else
            DocFileRow(doc: doc, onReplace: onPick, onRemove: onRemove),
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

  Widget _checkBox(bool value, ValueChanged<bool> onChanged, String text) {
    return InkWell(
      onTap: () => onChanged(!value),
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
                value: value,
                activeColor: AppColors.navy,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _store.status;
    final app = MockApplication.resolve(status);
    final expired = status.name == 'expired';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Renew Permit',
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
                'Renew your parking permit',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your updated documents. A renewal is reviewed like a new application.',
                style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'CURRENT PERMIT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                        StatusBadge(
                          text: expired ? 'EXPIRED' : 'EXPIRING SOON',
                          tone: expired ? BadgeTone.red : BadgeTone.gold,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      app.permitNo,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${app.plate}  \u2022  ${app.vehicleName}',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expired
                          ? 'Expired on ${app.validUntil}'
                          : 'Valid until ${app.validUntil}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: expired ? AppColors.error : AppColors.goldDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Confirm your vehicle',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              _checkBox(
                _unchanged,
                (v) => setState(() => _unchanged = v),
                'My vehicle and plate number have not changed.',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 6, 4, 0),
                child: Text(
                  'If you have a different vehicle, start a new application instead.',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Updated documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              _docCard(
                title: 'Vehicle OR/CR',
                hint: 'Your current OR/CR. The plate number must be readable.',
                isRequired: true,
                doc: _orcr,
                errorKey: 'orcr',
                onPick: () => _pick('orcr', (d) => _orcr = d),
                onRemove: () => setState(() => _orcr = null),
              ),
              _docCard(
                title: "Driver's License",
                hint: 'A valid license. Expired licenses will be declined.',
                isRequired: true,
                doc: _license,
                errorKey: 'license',
                onPick: () => _pick('license', (d) => _license = d),
                onRemove: () => setState(() => _license = null),
              ),
              _docCard(
                title: 'UCU ID',
                hint: 'Only upload a new one if your ID or details changed.',
                isRequired: false,
                doc: _ucuId,
                errorKey: 'ucu',
                onPick: () => _pick('ucu', (d) => _ucuId = d),
                onRemove: () => setState(() => _ucuId = null),
              ),
              const SizedBox(height: 6),
              _checkBox(
                _declared,
                (v) => setState(() => _declared = v),
                'I confirm that all documents I submitted are true and valid, and I agree to follow the UCU Safety and Campus Security guidelines.',
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Submit Renewal',
                showArrow: true,
                isLoading: _loading,
                onPressed: _canSubmit ? _submit : null,
              ),
              if (!_canSubmit && !_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Confirm your vehicle, upload your OR/CR and driver\'s license, and tick the confirmation to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
                  ),
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