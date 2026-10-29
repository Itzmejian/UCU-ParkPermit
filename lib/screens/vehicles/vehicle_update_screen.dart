import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/network_store.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/doc_picker.dart';
import '../../core/vehicle_validators.dart';
import '../../models/application_draft.dart';
import '../../models/application_store.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/doc_widgets.dart';
import '../../widgets/status_badge.dart';

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class VehicleUpdateScreen extends StatefulWidget {
  const VehicleUpdateScreen({super.key});

  @override
  State<VehicleUpdateScreen> createState() => _VehicleUpdateScreenState();
}

class _VehicleUpdateScreenState extends State<VehicleUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plate = TextEditingController();
  final TextEditingController _make = TextEditingController();
  final TextEditingController _color = TextEditingController();
  final TextEditingController _year = TextEditingController();

  VehicleRecord? _vehicle;
  bool _init = false;
  PickedDoc? _orcr;
  String? _orcrError;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final arg = ModalRoute.of(context)?.settings.arguments;
    final id = arg is int ? arg : 0;
    _vehicle = ApplicationStore.instance.vehicleById(id);
    final d = _vehicle?.draft;
    _plate.text = d?.plateDisplay ?? '';
    _make.text = d?.makeModel.trim() ?? '';
    _color.text = d?.color.trim() ?? '';
    _year.text = d?.modelYear.trim() ?? '';
    for (final c in [_plate, _make, _color, _year]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _color.dispose();
    _year.dispose();
    super.dispose();
  }

  String _norm(String s) => s.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  bool get _plateChanged =>
      _norm(_plate.text) != _norm(_vehicle?.draft.plate ?? '');

  bool get _anyChanged {
    final d = _vehicle?.draft;
    if (d == null) return false;
    return _plateChanged ||
        _make.text.trim() != d.makeModel.trim() ||
        _color.text.trim() != d.color.trim() ||
        _year.text.trim() != d.modelYear.trim();
  }

  bool get _canSubmit =>
      _vehicle != null &&
      _anyChanged &&
      (!_plateChanged || _orcr != null) &&
      !_loading;

  Future<void> _pickOrcr() async {
    final r = await pickDocument();
    if (!mounted || r == null) return;
    setState(() {
      if (r.error != null) {
        _orcrError = r.error;
      } else {
        _orcrError = null;
        _orcr = r.doc;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final v = _vehicle!;
    final plateChanged = _plateChanged;
    if (!NetworkStore.instance.ensureOnline(context)) return;
    setState(() => _loading = true);
    // TODO: send the update (and the new OR/CR) to Supabase.
    if (DataService.live) {
      final r = await DataService.updateVehicle(
        vehicle: v,
        plate: _plate.text.trim().toUpperCase(),
        makeModel: _make.text.trim(),
        color: _color.text.trim(),
        modelYear: _year.text.trim(),
        newOrcr: plateChanged ? _orcr : null,
      );
      if (!mounted) return;
      if (!r.ok) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.error ?? 'Could not update the vehicle.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(plateChanged ? 'Update sent for verification.' : 'Changes saved.'),
        ),
      );
      Navigator.pop(context);
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    ApplicationStore.instance.updateVehicle(
      v.id,
      plate: _plate.text.trim().toUpperCase(),
      makeModel: _make.text.trim(),
      color: _color.text.trim(),
      modelYear: _year.text.trim(),
      newOrcr: plateChanged ? _orcr : null,
      needsVerification: plateChanged,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(plateChanged ? 'Update sent for verification.' : 'Changes saved.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehicle;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vehicle not found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: 'Back', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      );
    }

    final plateChanged = _plateChanged;
    final moto = v.type == VehicleType.motorcycle;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Update',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Update vehicle details',
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Editing ${v.plate}  \u2022  ${v.type.label}. The vehicle type cannot be changed. To use a different type of vehicle, register a new one.',
                  style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Plate Number',
                  hint: 'e.g., ABC 1234',
                  icon: Icons.pin_outlined,
                  controller: _plate,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
                    LengthLimitingTextInputFormatter(10),
                    _UpperCaseFormatter(),
                  ],
                  validator: VehicleValidators.plate,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Vehicle Make / Model',
                  hint: moto ? 'e.g., Honda Click 125' : 'e.g., Toyota Vios 1.3 XLE',
                  icon: moto ? Icons.two_wheeler : Icons.directions_car_outlined,
                  controller: _make,
                  isRequired: true,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: VehicleValidators.makeModel,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Color',
                        hint: 'e.g., Pearl White',
                        icon: Icons.palette_outlined,
                        controller: _color,
                        isRequired: true,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: VehicleValidators.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Model Year',
                        hint: 'e.g., 2023',
                        icon: Icons.event_outlined,
                        controller: _year,
                        isRequired: true,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: VehicleValidators.modelYear,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (plateChanged) ...[
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
                        Icon(Icons.info_outline, size: 20, color: AppColors.goldDark),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A new plate number must be verified again by the Security Office. Upload your updated OR/CR. Verification takes about 24 hours.',
                            style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _orcrError != null ? AppColors.error : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Updated Vehicle OR/CR',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            StatusBadge(
                              text: _orcr != null ? 'UPLOADED' : 'REQUIRED',
                              tone: _orcr != null ? BadgeTone.green : BadgeTone.gold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_orcr == null)
                          DocEmptyPicker(onTap: _pickOrcr)
                        else
                          DocFileRow(
                            doc: _orcr!,
                            onReplace: _pickOrcr,
                            onRemove: () => setState(() => _orcr = null),
                          ),
                        if (_orcrError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _orcrError!,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 20, color: AppColors.navy),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Changes to the make or model, color, and model year are saved right away. Only a plate number change needs verification.',
                            style: TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: plateChanged ? 'Submit for Verification' : 'Save Changes',
                  showArrow: true,
                  isLoading: _loading,
                  onPressed: _canSubmit ? _submit : null,
                ),
                if (!_canSubmit && !_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      !_anyChanged
                          ? 'Change at least one detail to continue.'
                          : 'Upload your updated OR/CR to continue.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textHint),
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
      ),
    );
  }
}