import 'package:flutter/foundation.dart';
import '../core/app_limits.dart';
import 'application_draft.dart';
import 'permit_status.dart';

class SubmittedApplication {
  const SubmittedApplication({
    required this.draft,
    required this.referenceNo,
    required this.submittedAt,
  });

  final ApplicationDraft draft;
  final String referenceNo;
  final DateTime submittedAt;
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

/// In-memory data until the app is connected to Supabase.
class ApplicationStore extends ChangeNotifier {
  ApplicationStore._();

  static final ApplicationStore instance = ApplicationStore._();

  ApplicationDraft? draft;
  final List<SubmittedApplication> submittedList = [];
  PermitStatus status = PermitStatus.none;
  AppealRecord? lastAppeal;
  int _appealCount = 0;

  /// TESTING ONLY: pretend this many vehicle slots are used.
  int? debugSlots;

  SubmittedApplication? get submitted =>
      submittedList.isEmpty ? null : submittedList.last;

  int get slotsUsed => debugSlots ?? submittedList.length;

  bool get limitReached => slotsUsed >= kMaxVehicles;

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

  SubmittedApplication submit(ApplicationDraft d) {
    final now = DateTime.now();
    final number = 142 + submittedList.length;
    final sub = SubmittedApplication(
      draft: d,
      referenceNo: 'UCU-APP-${now.year}-${number.toString().padLeft(4, '0')}',
      submittedAt: now,
    );
    submittedList.add(sub);
    draft = null;
    status = PermitStatus.pending;
    notifyListeners();
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
    status = PermitStatus.appealReview;
    notifyListeners();
    return record;
  }
}