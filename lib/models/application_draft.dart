import 'dart:typed_data';

enum VehicleType { motorcycle, fourWheel }

extension VehicleTypeInfo on VehicleType {
  String get label =>
      this == VehicleType.motorcycle ? 'Motorcycle' : '4-Wheel Vehicle';
}

/// A document the applicant picked. The bytes are only present right after
/// picking a file (they are needed for the upload).
class PickedDoc {
  const PickedDoc({required this.name, required this.sizeBytes, this.bytes});

  final String name;
  final int sizeBytes;
  final Uint8List? bytes;

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

  /// What is saved in the server draft (the files are not saved).
  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType == null
          ? null
          : (vehicleType == VehicleType.motorcycle ? 'motorcycle' : 'four_wheel'),
      'plate': plate,
      'makeModel': makeModel,
      'color': color,
      'modelYear': modelYear,
    };
  }

  static ApplicationDraft fromJson(Map<String, dynamic> j, {int step = 0}) {
    final t = j['vehicleType'];
    return ApplicationDraft()
      ..vehicleType = t == 'motorcycle'
          ? VehicleType.motorcycle
          : (t == 'four_wheel' ? VehicleType.fourWheel : null)
      ..plate = (j['plate'] as String?) ?? ''
      ..makeModel = (j['makeModel'] as String?) ?? ''
      ..color = (j['color'] as String?) ?? ''
      ..modelYear = (j['modelYear'] as String?) ?? ''
      ..step = step;
  }
}