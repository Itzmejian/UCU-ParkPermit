import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/application_draft.dart';
import 'app_limits.dart';

class PickResult {
  const PickResult({this.doc, this.error});

  final PickedDoc? doc;
  final String? error;
}

/// Photos bigger than this are made smaller before they are uploaded.
const int kShrinkAboveBytes = 1024 * 1024;

/// Makes a photo smaller (JPG, longest side about 1600 px). Null if it fails.
Future<Uint8List?> compressImageBytes(Uint8List bytes) async {
  try {
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1600,
      minHeight: 1600,
      quality: 80,
      format: CompressFormat.jpeg,
    );
  } catch (_) {
    return null;
  }
}

String _asJpg(String name) {
  final i = name.lastIndexOf('.');
  final base = i < 0 ? name : name.substring(0, i);
  return '$base.jpg';
}

/// Opens the file picker. Returns null if the user cancelled.
Future<PickResult?> pickDocument() async {
  FilePickerResult? result;
  try {
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kAllowedExtensions,
      withData: true,
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

  var name = f.name;
  var size = f.size;
  Uint8List? bytes = f.bytes;

  // Make big photos smaller so they fit the limit and upload faster.
  if (ext != 'pdf' && bytes != null && size > kShrinkAboveBytes) {
    final small = await compressImageBytes(bytes);
    if (small != null && small.length < size) {
      bytes = small;
      size = small.length;
      name = _asJpg(name);
    }
  }

  if (size > kMaxUploadBytes) {
    final mb = (size / (1024 * 1024)).toStringAsFixed(1);
    return PickResult(
      error: ext == 'pdf'
          ? 'This PDF is $mb MB. The maximum is $kMaxUploadMb MB. Save it smaller, or upload a photo instead.'
          : 'This photo is $mb MB. The maximum is $kMaxUploadMb MB.',
    );
  }
  return PickResult(
    doc: PickedDoc(name: name, sizeBytes: size, bytes: bytes),
  );
}