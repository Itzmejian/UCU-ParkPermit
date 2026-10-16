import 'package:flutter/foundation.dart';
import '../core/app_limits.dart';
import 'application_draft.dart';
import 'permit_status.dart';

class SubmittedApplication {
  const SubmittedApplication({
    required this.draft,
    required this.referenceNo,
    required this.submittedAt,
    this.isRenewal = false,
  });

  final ApplicationDraft draft;
  final String referenceNo;
  final DateTime submittedAt;
  final bool isRenewal;
}

class AppealRecord {
  const AppealRecord({
    required this.ticketNo,
    required this.applicationRef,
    required this.submittedAt,
    required this.files,
    required this.statementLength,
  });

  final String ticketNo;
  final String applicationRef;
  final DateTime submittedAt;
  final List<String> files;
  final int statementLength;
}

class StickerReplacementRequest {
  const StickerReplacementRequest({
    required this.reason,
    required this.details,
    required this.requestedAt,
  });

  final String reason;
  final String details;
  final DateTime requestedAt;
}

/// A vehicle registered by the user, with the status of its permit.
class VehicleRecord {
  VehicleRecord({
    required this.id,
    required this.draft,
    required this.referenceNo,
    required this.registeredAt,
    this.status = PermitStatus.pending,
    this.pendingVerification = false,
  });

  final int id;
  final ApplicationDraft draft;
  String referenceNo;
  final DateTime registeredAt;
  PermitStatus status;

  /// True after a plate change, until the Security Office verifies it again.
  bool pendingVerification;

  VehicleType get type => draft.vehicleType ?? VehicleType.fourWheel;
  String get plate => draft.plateDisplay;
  String get makeModel => draft.makeModel.trim();
  String get title => makeModel.isEmpty ? plate : makeModel;
}

/// In-memory data until the app is connected to Supabase.
class ApplicationStore extends ChangeNotifier {
  ApplicationStore._();

  static final ApplicationStore instance = ApplicationStore._();

  ApplicationDraft? draft;
  final List<SubmittedApplication> submittedList = [];
  PermitStatus status = PermitStatus.none;
  AppealRecord? lastAppeal;
  StickerReplacementRequest? replacement;
  int _appealCount = 0;

  final List<VehicleRecord> _vehicles = [];
  VehicleRecord? _sampleVehicle;
  int _nextVehicleId = 1;

  /// TESTING ONLY: pretend this many vehicle slots are used.
  int? debugSlots;

  SubmittedApplication? get submitted =>
      submittedList.isEmpty ? null : submittedList.last;

  bool _hasVehicleStatus(PermitStatus s) =>
      s != PermitStatus.none && s != PermitStatus.draft;

  /// The user's vehicles. While testing with the status chips on Home and no
  /// real vehicle exists yet, one sample vehicle is shown.
  List<VehicleRecord> get vehicles {
    if (_vehicles.isNotEmpty) return List<VehicleRecord>.unmodifiable(_vehicles);
    if (_hasVehicleStatus(status)) {
      final sample = _sampleVehicle ?? _makeSample(status);
      _sampleVehicle = sample;
      sample.status = status;
      return [sample];
    }
    return const <VehicleRecord>[];
  }

  VehicleRecord? vehicleById(int id) {
    for (final v in vehicles) {
      if (v.id == id) return v;
    }
    return null;
  }

  bool isPrimary(int id) {
    final list = vehicles;
    return list.isNotEmpty && list.first.id == id;
  }

  int get slotsUsed => debugSlots ?? vehicles.length;

  bool get limitReached => slotsUsed >= kMaxVehicles;

  VehicleRecord _makeSample(PermitStatus s) {
    final d = ApplicationDraft()
      ..vehicleType = VehicleType.fourWheel
      ..plate = 'ABC 1234'
      ..makeModel = 'Toyota Vios 1.3 XLE'
      ..color = 'Pearl White'
      ..modelYear = '2023'
      ..license = const PickedDoc(name: 'drivers_license.jpg', sizeBytes: 1800000)
      ..orcr = const PickedDoc(name: 'lto_or_cr.pdf', sizeBytes: 2400000)
      ..ucuId = const PickedDoc(name: 'ucu_id.png', sizeBytes: 3100000);
    return VehicleRecord(
      id: 0,
      draft: d,
      referenceNo: 'UCU-APP-2026-0142',
      registeredAt: DateTime(2026, 10, 1),
      status: s,
    );
  }

  void setStatus(PermitStatus s) {
    status = s;
    if (_vehicles.isNotEmpty && _hasVehicleStatus(s)) {
      _vehicles.first.status = s;
    }
    notifyListeners();
  }

  void saveDraft(ApplicationDraft d) {
    draft = d;
    status = PermitStatus.draft;
    notifyListeners();
  }

  void discardDraft() {
    draft = null;
    if (status == PermitStatus.draft) status = PermitStatus.none;
    notifyListeners();
  }

  SubmittedApplication _add(ApplicationDraft d, {required bool renewal}) {
    final now = DateTime.now();
    final number = 142 + submittedList.length;
    final sub = SubmittedApplication(
      draft: d,
      referenceNo: 'UCU-APP-${now.year}-${number.toString().padLeft(4, '0')}',
      submittedAt: now,
      isRenewal: renewal,
    );
    submittedList.add(sub);
    return sub;
  }

  /// If only the sample vehicle is showing, keep it as a real vehicle first.
  void _promoteSample() {
    if (_vehicles.isEmpty) {
      final list = vehicles;
      if (list.isNotEmpty) _vehicles.add(list.first);
    }
    _sampleVehicle = null;
  }

  SubmittedApplication submit(ApplicationDraft d) {
    _promoteSample();
    final sub = _add(d, renewal: false);
    _vehicles.add(
      VehicleRecord(
        id: _nextVehicleId++,
        draft: d.clone(),
        referenceNo: sub.referenceNo,
        registeredAt: sub.submittedAt,
      ),
    );
    draft = null;
    // The Home dashboard follows the first (primary) vehicle.
    if (_vehicles.length == 1) status = PermitStatus.pending;
    notifyListeners();
    return sub;
  }

  SubmittedApplication submitRenewal(ApplicationDraft d) {
    final sub = _add(d, renewal: true);
    replacement = null;
    final list = vehicles;
    if (list.isNotEmpty) {
      final primary = list.first;
      primary.referenceNo = sub.referenceNo;
      primary.draft.orcr = d.orcr;
      primary.draft.license = d.license;
      if (d.ucuId != null) primary.draft.ucuId = d.ucuId;
      primary.pendingVerification = false;
    }
    setStatus(PermitStatus.pending);
    return sub;
  }

  AppealRecord submitAppeal({
    required String applicationRef,
    required List<String> files,
    required int statementLength,
  }) {
    final now = DateTime.now();
    final number = 142 + _appealCount;
    _appealCount++;
    final record = AppealRecord(
      ticketNo: 'APL-${now.year}-${number.toString().padLeft(4, '0')}',
      applicationRef: applicationRef,
      submittedAt: now,
      files: files,
      statementLength: statementLength,
    );
    lastAppeal = record;
    setStatus(PermitStatus.appealReview);
    return record;
  }

  void requestReplacement({required String reason, required String details}) {
    replacement = StickerReplacementRequest(
      reason: reason,
      details: details,
      requestedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Changes the vehicle details. A plate change needs verification again.
  void updateVehicle(
    int id, {
    required String plate,
    required String makeModel,
    required String color,
    required String modelYear,
    required bool needsVerification,
    PickedDoc? newOrcr,
  }) {
    final v = vehicleById(id);
    if (v == null) return;
    v.draft
      ..plate = plate
      ..makeModel = makeModel
      ..color = color
      ..modelYear = modelYear;
    if (newOrcr != null) v.draft.orcr = newOrcr;
    if (needsVerification) v.pendingVerification = true;
    notifyListeners();
  }

  /// TESTING ONLY: pretend the Security Office verified the update.
  void markVerified(int id) {
    final v = vehicleById(id);
    if (v == null) return;
    v.pendingVerification = false;
    notifyListeners();
  }

  void removeVehicle(int id) {
    if (_vehicles.isNotEmpty) {
      _vehicles.removeWhere((v) => v.id == id);
      status = _vehicles.isEmpty ? PermitStatus.none : _vehicles.first.status;
    } else if (_sampleVehicle != null && _sampleVehicle!.id == id) {
      _sampleVehicle = null;
      status = PermitStatus.none;
    }
    replacement = null;
    notifyListeners();
  }
}