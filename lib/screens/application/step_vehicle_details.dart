import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/vehicle_validators.dart';
import '../../models/application_draft.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/step_footer.dart';

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class StepVehicleDetails extends StatefulWidget {
  const StepVehicleDetails({
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
  State<StepVehicleDetails> createState() => _StepVehicleDetailsState();
}

class _StepVehicleDetailsState extends State<StepVehicleDetails> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plate;
  late final TextEditingController _make;
  late final TextEditingController _color;
  late final TextEditingController _year;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _plate = TextEditingController(text: d.plate);
    _make = TextEditingController(text: d.makeModel);
    _color = TextEditingController(text: d.color);
    _year = TextEditingController(text: d.modelYear);
    // Keep the draft up to date while typing, so nothing is lost when going back.
    _plate.addListener(() => d.plate = _plate.text);
    _make.addListener(() => d.makeModel = _make.text);
    _color.addListener(() => d.color = _color.text);
    _year.addListener(() => d.modelYear = _year.text);
  }

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _color.dispose();
    _year.dispose();
    super.dispose();
  }

  void _next() {
    if (_formKey.currentState!.validate()) widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final moto = widget.draft.isMotorcycle;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vehicle details',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your vehicle information exactly as it appears on your OR/CR.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
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
                    onSubmitted: (_) => _next(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
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
                  Icon(Icons.info_outline, size: 18, color: AppColors.navy),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Make sure your plate number matches your OR/CR to avoid delays. Your ID number and contact number are taken from your profile.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            StepFooter(
              primaryLabel: 'Next Step',
              onPrimary: _next,
              secondaryLabel: 'Back to Vehicle Type',
              onSecondary: widget.onBack,
              onSaveDraft: widget.onSaveDraft,
            ),
          ],
        ),
      ),
    );
  }
}