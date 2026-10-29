import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/application_draft.dart';
import '../models/application_store.dart';
import '../models/flagged_document.dart';
import '../models/notification_store.dart';
import '../models/permit_status.dart';

class ServiceResult {
  const ServiceResult.success([this.value])
      : ok = true,
        error = null;

  const ServiceResult.failure(this.error)
      : ok = false,
        value = null;

  final bool ok;
  final String? error;
  final String? value;
}

class AppealUpload {
  const AppealUpload({required this.kind, required this.doc});

  final String kind;
  final PickedDoc doc;
}

/// Everything the app saves to, and loads from, the Supabase database.
/// In prototype mode (no Supabase) these methods do nothing.
class DataService {
  DataService._();

  static const String _bucket = 'documents';

  static bool get live => kSupabaseReady;

  static SupabaseClient get _c => Supabase.instance.client;

  static String? get _uid => _c.auth.currentUser?.id;

  /// True while data is being loaded (used by the refresh button).
  static final ValueNotifier<bool> refreshing = ValueNotifier<bool>(false);

  // ---------- helpers ----------

  static String _mime(String ext) {
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  static String _kindLabel(String kind) {
    switch (kind) {
      case 'drivers_license':
        return "Driver's License";
      case 'orcr':
        return 'Vehicle OR/CR';
      default:
        return 'UCU ID';
    }
  }

  static DateTime? _dt(dynamic v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  static DateTime? _day(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  static String _friendly(Object e) {
    if (e is PostgrestException) {
      final m = e.message;
      if (m.contains('VEHICLE_LIMIT')) return 'You already have the maximum of 2 vehicles.';
      if (m.contains('PROFILE_INCOMPLETE')) return 'Please complete your profile first.';
      if (m.contains('APPEAL_EXPIRED')) return 'The 7-day appeal window has ended.';
      if (m.contains('APPEAL_EXISTS')) return 'You already filed an appeal for this application.';
      if (m.contains('NOT_DECLINED')) return 'This application is not declined.';
      if (m.contains('DOCUMENTS_MISSING')) return 'Please attach all the required documents.';
      if (m.contains('REQUEST_EXISTS')) return 'A replacement request is already open.';
      if (m.contains('UPDATE_PENDING')) return 'Your last update is still waiting for verification.';
      if (m.contains('APPLICATION_OPEN')) return 'You still have an application being reviewed.';
      if (m.contains('NOT_ALLOWED') || m.contains('NOT_AUTHENTICATED')) {
        return 'This is not allowed right now. Refresh and try again.';
      }
      if (e.code == '23505' && m.contains('vehicles_plate')) {
        return 'This plate number is already registered.';
      }
      if (e.code == '23505') return 'This record already exists.';
      return m;
    }
    if (e is StorageException) return 'Could not upload a file: ${e.message}';
    if (e is AuthException) return e.message;
    if (e is StateError && e.message == 'FILE_NOT_LOADED') {
      return 'Please choose your files again.';
    }
    return 'Something went wrong. Check your internet connection and try again.';
  }

  static Future<Map<String, dynamic>> _upload(
    String uid,
    String kind,
    PickedDoc doc,
  ) async {
    final bytes = doc.bytes;
    if (bytes == null) throw StateError('FILE_NOT_LOADED');
    final ext = doc.extension;
    final mime = _mime(ext);
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$kind.$ext';
    await _c.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mime),
        );
    return {
      'kind': kind,
      'path': path,
      'name': doc.name,
      'size': doc.sizeBytes,
      'mime': mime,
    };
  }

  static Future<void> _cleanup(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _c.storage.from(_bucket).remove(paths);
    } catch (_) {}
  }

  // ---------- loading ----------

  static PermitStatus _statusFor(Map<String, dynamic>? app, Map<String, dynamic>? permit) {
    if (app == null) return PermitStatus.pending;
    final s = (app['status'] as String?) ?? 'pending';
    switch (s) {
      case 'under_review':
        return PermitStatus.underReview;
      case 'declined':
        return PermitStatus.declined;
      case 'appeal_review':
        return PermitStatus.appealReview;
      case 'approved':
        if (permit == null) return PermitStatus.approved;
        final sticker = permit['sticker_status'];
        if (sticker == 'preparing') return PermitStatus.approved;
        if (sticker == 'ready') return PermitStatus.stickerReady;
        final until = _day(permit['valid_until']);
        if (until != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          if (until.isBefore(today)) return PermitStatus.expired;
          if (until.difference(today).inDays <= 30) return PermitStatus.expiringSoon;
        }
        return PermitStatus.active;
      default:
        return PermitStatus.pending;
    }
  }

  /// Loads everything of the signed-in user from the database into the app.
  static Future<void> refresh({bool initial = false}) async {
    if (!live) return;
    final user = _c.auth.currentUser;
    if (user == null) return;
    final uid = user.id;
    final notif = NotificationStore.instance;
    if (initial) notif.muted = true;
    refreshing.value = true;
    try {
      final r = await Future.wait<dynamic>([
        _c.from('vehicles').select().eq('owner_id', uid).eq('active', true).order('created_at'),
        _c.from('applications').select().eq('applicant_id', uid).order('created_at'),
        _c.from('permits').select('*, parking_zones(code, name)').eq('owner_id', uid).order('created_at'),
        _c.from('documents').select().eq('owner_id', uid).order('created_at'),
        _c.from('appeals').select().eq('applicant_id', uid).order('created_at'),
        _c.from('sticker_replacements').select().eq('owner_id', uid).order('created_at'),
        _c.from('application_drafts').select().eq('user_id', uid).maybeSingle(),
      ]);
      _apply(r);
    } catch (_) {
      // Keep what is already shown if loading fails.
    } finally {
      if (initial) {
        notif.rebase();
        notif.muted = false;
      }
      refreshing.value = false;
    }
  }

  static void _apply(List<dynamic> r) {
    List<Map<String, dynamic>> rows(dynamic x) => (x as List).cast<Map<String, dynamic>>();

    final vehicleRows = rows(r[0]);
    final appRows = rows(r[1]);
    final permitRows = rows(r[2]);
    final docRows = rows(r[3]);
    final appealRows = rows(r[4]);
    final replRows = rows(r[5]);
    final draftRow = r[6] as Map<String, dynamic>?;

    final vehicles = <VehicleRecord>[];
    final submitted = <SubmittedApplication>[];
    AppealRecord? appeal;
    StickerReplacementRequest? replacement;
    var localId = 1;

    for (final v in vehicleRows) {
      final vid = v['id'] as String;
      final apps = appRows.where((a) => a['vehicle_id'] == vid).toList();
      final latestApp = apps.isEmpty ? null : apps.last;
      final permits = permitRows.where((p) => p['vehicle_id'] == vid).toList();
      final latestPermit = permits.isEmpty ? null : permits.last;

      Map<String, dynamic>? appPermit;
      if (latestApp != null) {
        for (final p in permits) {
          if (p['application_id'] == latestApp['id']) appPermit = p;
        }
      }
      final permitForInfo = appPermit ?? latestPermit;

      final appIds = apps.map((a) => a['id']).toSet();
      final vDocs = docRows.where((d) => appIds.contains(d['application_id'])).toList();

      PickedDoc? docOf(String kind) {
        PickedDoc? found;
        for (final d in vDocs) {
          if (d['kind'] == kind && d['review_status'] != 'replaced') {
            found = PickedDoc(
              name: (d['file_name'] as String?) ?? 'file',
              sizeBytes: (d['size_bytes'] as num?)?.toInt() ?? 0,
            );
          }
        }
        return found;
      }

      final draft = ApplicationDraft()
        ..vehicleType = v['vehicle_type'] == 'motorcycle'
            ? VehicleType.motorcycle
            : VehicleType.fourWheel
        ..plate = (v['plate_number'] as String?) ?? ''
        ..makeModel = (v['make_model'] as String?) ?? ''
        ..color = (v['color'] as String?) ?? ''
        ..modelYear = '${v['model_year'] ?? ''}'
        ..license = docOf('drivers_license')
        ..orcr = docOf('orcr')
        ..ucuId = docOf('ucu_id')
        ..declarationAccepted = true;

      final flagged = <FlaggedDocument>[];
      if (latestApp != null) {
        for (final d in docRows) {
          if (d['application_id'] == latestApp['id'] && d['review_status'] == 'rejected') {
            final kind = d['kind'] as String;
            flagged.add(
              FlaggedDocument(
                title: _kindLabel(kind),
                remark: (d['reviewer_remark'] as String?) ?? 'Please upload a clearer copy.',
                kind: kind,
              ),
            );
          }
        }
      }

      String? zone;
      final zoneMap = permitForInfo?['parking_zones'];
      if (zoneMap is Map) zone = zoneMap['name'] as String?;

      // The first vehicle is the primary one: it drives the Home screen.
      if (vehicles.isEmpty) {
        if (permitForInfo != null) {
          for (final x in replRows) {
            if (x['permit_id'] == permitForInfo['id'] && x['status'] == 'requested') {
              replacement = StickerReplacementRequest(
                reason: (x['reason'] as String?) ?? '',
                details: (x['details'] as String?) ?? '',
                requestedAt: _dt(x['created_at']) ?? DateTime.now(),
              );
            }
          }
        }
        if (latestApp != null) {
          for (final a in appealRows) {
            if (a['application_id'] == latestApp['id']) {
              final files = [
                for (final d in docRows)
                  if (d['appeal_id'] == a['id']) (d['file_name'] as String?) ?? 'file',
              ];
              appeal = AppealRecord(
                ticketNo: a['ticket_no'] as String,
                applicationRef: latestApp['reference_no'] as String,
                submittedAt: _dt(a['created_at']) ?? DateTime.now(),
                files: files,
                statementLength: ((a['statement'] as String?) ?? '').length,
              );
            }
          }
        }
      }

      vehicles.add(
        VehicleRecord(
          id: localId++,
          draft: draft,
          referenceNo: (latestApp?['reference_no'] as String?) ?? '-',
          registeredAt: _dt(v['created_at']) ?? DateTime.now(),
          status: _statusFor(latestApp, appPermit),
          pendingVerification: v['pending_verification'] == true,
          remoteId: vid,
          applicationId: latestApp?['id'] as String?,
          permitId: permitForInfo?['id'] as String?,
          permitNo: permitForInfo?['permit_no'] as String?,
          zoneLabel: zone,
          validFrom: _day(permitForInfo?['valid_from']),
          validUntil: _day(permitForInfo?['valid_until']),
          stickerStatus: permitForInfo?['sticker_status'] as String?,
          flagged: flagged,
          officerNote: latestApp?['officer_note'] as String?,
        ),
      );

      for (final a in apps) {
        submitted.add(
          SubmittedApplication(
            draft: draft,
            referenceNo: a['reference_no'] as String,
            submittedAt: _dt(a['submitted_at']) ?? DateTime.now(),
            isRenewal: a['kind'] == 'renewal',
          ),
        );
      }
    }
    submitted.sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

    ApplicationDraft? savedDraft;
    if (draftRow != null) {
      final data = draftRow['data'];
      if (data is Map<String, dynamic>) {
        savedDraft = ApplicationDraft.fromJson(
          data,
          step: (draftRow['step'] as num?)?.toInt() ?? 0,
        );
      }
    }

    ApplicationStore.instance.loadSnapshot(
      vehicles: vehicles,
      submitted: submitted,
      draft: savedDraft,
      appeal: appeal,
      replacement: replacement,
    );
  }

  /// Forgets all data (used when logging out).
  static void clear() {
    ApplicationStore.instance.clear();
  }

  // ---------- drafts ----------

  static Future<void> saveDraft(ApplicationDraft d) async {
    if (!live) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      await _c.from('application_drafts').upsert({
        'user_id': uid,
        'data': d.toJson(),
        'step': d.step,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> discardDraft() async {
    if (!live) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      await _c.from('application_drafts').delete().eq('user_id', uid);
    } catch (_) {}
  }

  // ---------- actions ----------

  /// Uploads the 3 documents and creates the vehicle and the application.
  static Future<ServiceResult> submitApplication(ApplicationDraft d) async {
    final uid = _uid;
    if (uid == null) return const ServiceResult.failure('Please log in again.');
    final files = <String, PickedDoc?>{
      'drivers_license': d.license,
      'orcr': d.orcr,
      'ucu_id': d.ucuId,
    };
    if (files.values.any((f) => f == null)) {
      return const ServiceResult.failure('Please attach all 3 documents.');
    }
    final year = int.tryParse(d.modelYear.trim());
    if (year == null || d.vehicleType == null) {
      return const ServiceResult.failure('Please check your vehicle details.');
    }

    final paths = <String>[];
    try {
      final docs = <Map<String, dynamic>>[];
      for (final e in files.entries) {
        final up = await _upload(uid, e.key, e.value!);
        paths.add(up['path'] as String);
        docs.add(up);
      }
      final ref = await _c.rpc('submit_application', params: {
        'p_vehicle_type':
            d.vehicleType == VehicleType.motorcycle ? 'motorcycle' : 'four_wheel',
        'p_plate': d.plateDisplay,
        'p_make_model': d.makeModel.trim(),
        'p_color': d.color.trim(),
        'p_model_year': year,
        'p_documents': docs,
      });
      await refresh();
      return ServiceResult.success(ref.toString());
    } catch (e) {
      await _cleanup(paths);
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> submitRenewal({
    required PickedDoc orcr,
    required PickedDoc license,
    PickedDoc? ucuId,
  }) async {
    final uid = _uid;
    if (uid == null) return const ServiceResult.failure('Please log in again.');
    final vehicles = ApplicationStore.instance.vehicles;
    final vehicleId = vehicles.isEmpty ? null : vehicles.first.remoteId;
    if (vehicleId == null) {
      return const ServiceResult.failure('Could not find your vehicle. Refresh and try again.');
    }
    final paths = <String>[];
    try {
      final docs = <Map<String, dynamic>>[];
      final files = <String, PickedDoc?>{
        'orcr': orcr,
        'drivers_license': license,
        'ucu_id': ucuId,
      };
      for (final e in files.entries) {
        final doc = e.value;
        if (doc == null) continue;
        final up = await _upload(uid, e.key, doc);
        paths.add(up['path'] as String);
        docs.add(up);
      }
      final ref = await _c.rpc('submit_renewal', params: {
        'p_vehicle_id': vehicleId,
        'p_documents': docs,
      });
      await refresh();
      return ServiceResult.success(ref.toString());
    } catch (e) {
      await _cleanup(paths);
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> submitAppeal({
    required String statement,
    required List<AppealUpload> uploads,
  }) async {
    final uid = _uid;
    if (uid == null) return const ServiceResult.failure('Please log in again.');
    final vehicles = ApplicationStore.instance.vehicles;
    final appId = vehicles.isEmpty ? null : vehicles.first.applicationId;
    if (appId == null) {
      return const ServiceResult.failure('Could not find your application. Refresh and try again.');
    }
    final paths = <String>[];
    try {
      final docs = <Map<String, dynamic>>[];
      for (final u in uploads) {
        final up = await _upload(uid, u.kind, u.doc);
        paths.add(up['path'] as String);
        docs.add(up);
      }
      final ticket = await _c.rpc('submit_appeal', params: {
        'p_application_id': appId,
        'p_statement': statement,
        'p_documents': docs,
      });
      await refresh();
      return ServiceResult.success(ticket.toString());
    } catch (e) {
      await _cleanup(paths);
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> requestReplacement({
    required String reason,
    required String details,
  }) async {
    final vehicles = ApplicationStore.instance.vehicles;
    final permitId = vehicles.isEmpty ? null : vehicles.first.permitId;
    if (permitId == null) {
      return const ServiceResult.failure('Could not find your permit. Refresh and try again.');
    }
    try {
      await _c.rpc('request_sticker_replacement', params: {
        'p_permit_id': permitId,
        'p_reason': reason,
        'p_details': details,
      });
      await refresh();
      return const ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> updateVehicle({
    required VehicleRecord vehicle,
    required String plate,
    required String makeModel,
    required String color,
    required String modelYear,
    PickedDoc? newOrcr,
  }) async {
    final uid = _uid;
    final rid = vehicle.remoteId;
    if (uid == null || rid == null) {
      return const ServiceResult.failure('Please log in again.');
    }
    final year = int.tryParse(modelYear);
    if (year == null) return const ServiceResult.failure('Please check the model year.');
    final paths = <String>[];
    try {
      final params = <String, dynamic>{
        'p_vehicle_id': rid,
        'p_plate': plate,
        'p_make_model': makeModel,
        'p_color': color,
        'p_model_year': year,
      };
      if (newOrcr != null) {
        final up = await _upload(uid, 'orcr', newOrcr);
        paths.add(up['path'] as String);
        params['p_orcr'] = up;
      }
      await _c.rpc('update_vehicle', params: params);
      await refresh();
      return const ServiceResult.success();
    } catch (e) {
      await _cleanup(paths);
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> createSupportTicket({
    required String topic,
    required String subject,
    required String message,
  }) async {
    try {
      final r = await _c.rpc('create_support_ticket', params: {
        'p_topic': topic,
        'p_subject': subject,
        'p_message': message,
      });
      return ServiceResult.success(r.toString());
    } catch (e) {
      if (e is PostgrestException && e.message.contains('TOO_MANY')) {
        return const ServiceResult.failure(
          'You sent too many messages. Please try again later.',
        );
      }
      return ServiceResult.failure(_friendly(e));
    }
  }

  static Future<ServiceResult> removeVehicle(VehicleRecord vehicle) async {
    final rid = vehicle.remoteId;
    if (rid == null) return const ServiceResult.failure('Could not find the vehicle.');
    try {
      await _c.rpc('remove_vehicle', params: {'p_vehicle_id': rid});
      await refresh();
      return const ServiceResult.success();
    } catch (e) {
      return ServiceResult.failure(_friendly(e));
    }
  }
}