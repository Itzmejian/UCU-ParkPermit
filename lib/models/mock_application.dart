import '../core/date_format.dart';
import 'application_draft.dart';
import 'application_store.dart';
import 'flagged_document.dart';
import 'permit_status.dart';

export 'flagged_document.dart';

/// Sample data for the prototype. When the user has real vehicle data
/// (from Supabase or from the wizard), that data replaces the sample.
class MockApplication {
  const MockApplication({
    required this.referenceNo,
    required this.vehicleName,
    required this.plate,
    required this.vehicleType,
    required this.zone,
    required this.permitNo,
    required this.validUntil,
    required this.flagged,
    required this.officerNote,
    this.validFrom,
  });

  final String referenceNo;
  final String vehicleName;
  final String plate;
  final String vehicleType;
  final String zone;
  final String permitNo;
  final String validUntil;
  final String? validFrom;
  final List<FlaggedDocument> flagged;
  final String officerNote;

  MockApplication copyWith({
    String? referenceNo,
    String? vehicleName,
    String? plate,
    String? vehicleType,
  }) {
    return MockApplication(
      referenceNo: referenceNo ?? this.referenceNo,
      vehicleName: vehicleName ?? this.vehicleName,
      plate: plate ?? this.plate,
      vehicleType: vehicleType ?? this.vehicleType,
      zone: zone,
      permitNo: permitNo,
      validUntil: validUntil,
      validFrom: validFrom,
      flagged: flagged,
      officerNote: officerNote,
    );
  }

  static MockApplication forStatus(PermitStatus status) {
    final String validUntil = switch (status) {
      PermitStatus.expiringSoon => 'November 7, 2026',
      PermitStatus.expired => 'September 30, 2026',
      _ => 'July 31, 2027',
    };
    return MockApplication(
      referenceNo: 'UCU-APP-2026-0142',
      vehicleName: 'Toyota Vios 1.3 XLE',
      plate: 'ABC 1234',
      vehicleType: '4-Wheel Vehicle (Sedan)',
      zone: 'Zone A & B (Main Campus)',
      permitNo: 'UCU-PP-2026-0001',
      validUntil: validUntil,
      flagged: const [
        FlaggedDocument(
          title: 'Vehicle OR/CR',
          remark:
              'The plate number is not readable in the photo. Upload a clearer, uncropped copy.',
          kind: 'orcr',
        ),
      ],
      officerNote:
          'Please upload a clear, complete copy of your OR/CR so we can issue your permit.',
    );
  }

  /// The sample data with the details of one real vehicle on top.
  static MockApplication forVehicle(VehicleRecord v) {
    return _overlay(forStatus(v.status), v);
  }

  static MockApplication _overlay(MockApplication base, VehicleRecord v) {
    final d = v.draft;
    final live = v.remoteId != null;
    return MockApplication(
      referenceNo: v.referenceNo,
      vehicleName: d.makeModel.trim().isEmpty ? base.vehicleName : d.makeModel.trim(),
      plate: d.plate.trim().isEmpty ? base.plate : d.plateDisplay,
      vehicleType: d.vehicleType?.label ?? base.vehicleType,
      zone: v.zoneLabel ?? base.zone,
      permitNo: v.permitNo ?? base.permitNo,
      validUntil: v.validUntil == null ? base.validUntil : formatLongDate(v.validUntil!),
      validFrom: v.validFrom == null ? null : formatLongDate(v.validFrom!),
      flagged: live ? v.flagged : base.flagged,
      officerNote: live ? (v.officerNote ?? '') : base.officerNote,
    );
  }

  /// The data for the primary vehicle (or the sample if there is none).
  static MockApplication resolve(PermitStatus status) {
    final base = forStatus(status);
    final store = ApplicationStore.instance;
    if (status == PermitStatus.draft) {
      final ApplicationDraft? d = store.draft;
      if (d == null) return base;
      return base.copyWith(
        vehicleName: d.makeModel.trim().isEmpty ? null : d.makeModel.trim(),
        plate: d.plate.trim().isEmpty ? null : d.plateDisplay,
        vehicleType: d.vehicleType?.label,
      );
    }
    final vehicles = store.vehicles;
    if (vehicles.isEmpty) return base;
    return _overlay(base, vehicles.first);
  }
}