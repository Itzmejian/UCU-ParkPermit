import 'package:file_picker/file_picker.dart';
import '../models/application_draft.dart';
import 'app_limits.dart';

class PickResult {
  const PickResult({this.doc, this.error});

  final PickedDoc? doc;
  final String? error;
}

/// Opens the file picker. Returns null if the user cancelled.
Future<PickResult?> pickDocument() async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kAllowedExtensions,
      withData: false,
    );
  } catch (_) {
    return const PickResult(
      error: 'Could not open the file picker. Please try again.',
    );
  }
  if (result == null || result.files.isEmpty) return null;

  final f = result.files.first;
  final ext = (f.extension ?? '').toLowerCase();
  if (!kAllowedExtensions.contains(ext)) {
    return const PickResult(error: 'Only PDF, JPG or PNG files are allowed.');
  }
  if (f.size > kMaxUploadBytes) {
    final mb = (f.size / (1024 * 1024)).toStringAsFixed(1);
    return PickResult(
      error: 'This file is $mb MB. The maximum is $kMaxUploadMb MB.',
    );
  }
  return PickResult(doc: PickedDoc(name: f.name, sizeBytes: f.size));
}