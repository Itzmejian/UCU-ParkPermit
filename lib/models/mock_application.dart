import 'application_draft.dart';
import 'application_store.dart';
import 'permit_status.dart';

class FlaggedDocument {
  const FlaggedDocument({required this.title, required this.remark});

  final String title;
  final String remark;
}

/// Sample data used until the app is connected to Supabase.
/// If the user filled in the wizard, their own vehicle details replace the sample.
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
  });

  final String referenceNo;
  final String vehicleName;
  final String plate;
  final String vehicleType;
  final String zone;
  final String permitNo;
  final String validUntil;
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
        ),
      ],
      officerNote:
          'Please upload a clear, complete copy of your OR/CR so we can issue your permit.',
    );
  }

  /// Sample data, with the user's own vehicle details when they have any.
  static MockApplication resolve(PermitStatus status) {
    final base = forStatus(status);
    final store = ApplicationStore.instance;
    final sub = store.submitted;
    final d = store.draft ?? sub?.draft;
    if (d == null) return base;
    return base.copyWith(
      referenceNo: sub?.referenceNo,
      vehicleName: d.makeModel.trim().isEmpty ? null : d.makeModel.trim(),
      plate: d.plate.trim().isEmpty ? null : d.plateDisplay,
      vehicleType: d.vehicleType?.label,
    );
  }
}