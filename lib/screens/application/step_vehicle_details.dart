import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/app_limits.dart';
import '../../core/doc_picker.dart';
import '../../core/orcr_parser.dart';
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

  bool _scanning = false;
  String? _scanMessage;
  bool _scanOk = false;

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

/// ML Kit reads a form column by column (all labels, then all values).
  /// This puts text on the same row back together, left to right, so
  /// "MAKE/BRAND:" and "TOYOTA" become one line again.
  List<String> _rowsFrom(RecognizedText result) {
    final items = <TextLine>[
      for (final block in result.blocks) ...block.lines,
    ];
    items.sort((a, b) =>
        a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));
    final rows = <List<TextLine>>[];
    for (final line in items) {
      final box = line.boundingBox;
      if (rows.isNotEmpty) {
        final ref = rows.last.first.boundingBox;
        final h = box.height < ref.height ? box.height : ref.height;
        if ((box.center.dy - ref.center.dy).abs() < h * 0.6) {
          rows.last.add(line);
          continue;
        }
      }
      rows.add([line]);
    }
    return [
      for (final r in rows)
        (r..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left)))
            .map((l) => l.text)
            .join(' '),
    ];
  }

  /// Takes or picks a photo of the OR/CR, reads it on the phone and fills in
  /// what it found. Nothing is sent to the internet for this.
  Future<void> _scan(ImageSource source) async {
    FocusScope.of(context).unfocus();
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
    } catch (_) {
      setState(() {
        _scanOk = false;
        _scanMessage = source == ImageSource.camera
            ? 'Could not open the camera. Please try again.'
            : 'Could not open your photos. Please try again.';
      });
      return;
    }
    if (photo == null) return;
    setState(() {
      _scanning = true;
      _scanMessage = null;
    });

    var lines = <String>[];
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result =
          await recognizer.processImage(InputImage.fromFilePath(photo.path));
      lines = _rowsFrom(result);
    } catch (_) {
      lines = <String>[];
    } finally {
      await recognizer.close();
    }
    final found = parseOrcr(lines);

    // Use the same photo as the OR/CR document if none was added yet.
    var attached = false;
    if (widget.draft.orcr == null) {
      try {
        var bytes = await photo.readAsBytes();
        if (bytes.length > kShrinkAboveBytes) {
          final small = await compressImageBytes(bytes);
          if (small != null && small.length < bytes.length) bytes = small;
        }
        if (bytes.length <= kMaxUploadBytes) {
          widget.draft.orcr = PickedDoc(
            name: 'orcr_scan.jpg',
            sizeBytes: bytes.length,
            bytes: bytes,
          );
          attached = true;
        }
      } catch (_) {}
    }
    if (!mounted) return;

    final filled = <String>[];
    setState(() {
      if (found.plate != null) {
        _plate.text = found.plate!;
        filled.add('plate number');
      }
      if (found.makeModel != null) {
        _make.text = found.makeModel!;
        filled.add('make / model');
      }
      if (found.color != null) {
        _color.text = found.color!;
        filled.add('color');
      }
      if (found.year != null) {
        _year.text = found.year!;
        filled.add('model year');
      }
      _scanning = false;
      _scanOk = filled.isNotEmpty;
      var message = filled.isEmpty
          ? 'We could not read the details. Try again in good light with the whole OR/CR in the photo, or type them in.'
          : 'Filled in: ${filled.join(', ')}. Please check them before you continue.';
      if (attached) {
        message = '$message The photo was also added as your OR/CR in the next step.';
      }
      _scanMessage = message;
    });
  }

  Widget _scanCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.document_scanner_outlined, size: 24, color: AppColors.navy),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan your OR/CR',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Take a photo of your Certificate of Registration and we will fill in the details for you. The photo is read on your phone.',
                      style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_scanning)
            const Column(
              children: [
                LinearProgressIndicator(color: AppColors.navy),
                SizedBox(height: 8),
                Text(
                  'Reading your OR/CR...',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Take photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Choose photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.navy),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          if (_scanMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _scanOk ? AppColors.successLight : AppColors.goldLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _scanOk ? AppColors.success : AppColors.gold),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _scanOk ? Icons.check_circle_outline : Icons.info_outline,
                    size: 18,
                    color: _scanOk ? AppColors.success : AppColors.goldDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scanMessage!,
                      style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
            const SizedBox(height: 16),
            if (!kIsWeb) ...[
              _scanCard(),
              const SizedBox(height: 18),
            ],
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