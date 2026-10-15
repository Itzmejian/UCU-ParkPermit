enum VehicleType { motorcycle, fourWheel }

extension VehicleTypeInfo on VehicleType {
  String get label =>
      this == VehicleType.motorcycle ? 'Motorcycle' : '4-Wheel Vehicle';
}

/// A document the applicant picked. Only the name and size are kept here;
/// the real file is uploaded to Supabase Storage later.
class PickedDoc {
  const PickedDoc({required this.name, required this.sizeBytes});

  final String name;
  final int sizeBytes;

  String get extension {
    final i = name.lastIndexOf('.');
    return i < 0 ? '' : name.substring(i + 1).toLowerCase();
  }

  bool get isPdf => extension == 'pdf';

  String get sizeLabel {
    if (sizeBytes < 1024 * 1024) {
      final kb = (sizeBytes / 1024).ceil();
      return '${kb < 1 ? 1 : kb} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ApplicationDraft {
  VehicleType? vehicleType;
  String plate = '';
  String makeModel = '';
  String color = '';
  String modelYear = '';
  PickedDoc? license;
  PickedDoc? orcr;
  PickedDoc? ucuId;
  bool declarationAccepted = false;
  bool helmetAccepted = false;
  int step = 0;

  bool get isMotorcycle => vehicleType == VehicleType.motorcycle;

  bool get hasAllDocuments => license != null && orcr != null && ucuId != null;

  String get plateDisplay => plate.trim().toUpperCase();

  bool get hasAnyData =>
      vehicleType != null ||
      plate.trim().isNotEmpty ||
      makeModel.trim().isNotEmpty ||
      color.trim().isNotEmpty ||
      modelYear.trim().isNotEmpty ||
      license != null ||
      orcr != null ||
      ucuId != null;

  ApplicationDraft clone() {
    return ApplicationDraft()
      ..vehicleType = vehicleType
      ..plate = plate
      ..makeModel = makeModel
      ..color = color
      ..modelYear = modelYear
      ..license = license
      ..orcr = orcr
      ..ucuId = ucuId
      ..declarationAccepted = declarationAccepted
      ..helmetAccepted = helmetAccepted
      ..step = step;
  }
}