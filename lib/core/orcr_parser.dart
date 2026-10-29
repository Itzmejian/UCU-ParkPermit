// Reads vehicle details from the text of a photographed LTO OR/CR.
// Text recognition is never perfect, so the applicant always checks the result.

class OrcrResult {
  const OrcrResult({this.plate, this.makeModel, this.color, this.year});

  final String? plate;
  final String? makeModel;
  final String? color;
  final String? year;
}

final RegExp _plateLetters = RegExp(r'\b([A-Z]{2,3})[ \-]?(\d{3,5})\b');
final RegExp _plateDigits = RegExp(r'\b(\d{3,4})[ \-]?([A-Z]{2,3})\b');
final RegExp _plateLineLetters = RegExp(r'^([A-Z]{2,3})[ \-]?(\d{3,5})$');
final RegExp _plateLineDigits = RegExp(r'^(\d{3,4})[ \-]?([A-Z]{2,3})$');
final RegExp _yearRe = RegExp(r'\b(19[89]\d|20\d\d)\b');

const List<String> _stops = [
  ' SERIES', ' MODEL', ' BODY', ' COLOR', ' YEAR', ' TYPE', ' FUEL',
  ' ENGINE', ' CHASSIS', ' PLATE', ' MAKE', ' GROSS', ' NET', ' MV FILE',
];

String _clean(String s) => s.replaceAll(RegExp(r'^[\s:.\-#/]+'), '').trim();

/// Stops at the next label on the same line, e.g. "TOYOTA SERIES VIOS" -> "TOYOTA".
String _cut(String s) {
  var end = s.length;
  for (final stop in _stops) {
    final i = s.indexOf(stop);
    if (i > 0 && i < end) end = i;
  }
  return s.substring(0, end).trim();
}

String _title(String s) {
  return s
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0] + w.substring(1).toLowerCase())
      .join(' ');
}

/// The text after a label on the same line, or the next line.
String? _afterLabel(
  List<String> lines,
  List<String> labels, {
  List<String> exclude = const [],
}) {
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (exclude.any(line.contains)) continue;
    for (final label in labels) {
      final at = line.indexOf(label);
      if (at < 0) continue;
      final rest = _clean(line.substring(at + label.length));
      if (rest.length >= 2) return rest;
      if (i + 1 < lines.length) {
        final next = lines[i + 1].trim();
        if (next.length >= 2) return next;
      }
    }
  }
  return null;
}

String? _plateFrom(String text) {
  final a = _plateLetters.firstMatch(text);
  if (a != null) return '${a.group(1)} ${a.group(2)}';
  final b = _plateDigits.firstMatch(text);
  if (b != null) return '${b.group(1)} ${b.group(2)}';
  return null;
}

OrcrResult parseOrcr(List<String> rawLines) {
  final lines = [
    for (final l in rawLines) l.toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim(),
  ]..removeWhere((l) => l.isEmpty);
  if (lines.isEmpty) return const OrcrResult();

  // Plate number: next to its label, or a line that is only a plate number.
  String? plate;
  final plateText = _afterLabel(lines, const ['PLATE NO', 'PLATE NUMBER', 'PLATE']);
  if (plateText != null) plate = _plateFrom(plateText);
  if (plate == null) {
    for (final l in lines) {
      final a = _plateLineLetters.firstMatch(l);
      if (a != null) {
        plate = '${a.group(1)} ${a.group(2)}';
        break;
      }
      final b = _plateLineDigits.firstMatch(l);
      if (b != null) {
        plate = '${b.group(1)} ${b.group(2)}';
        break;
      }
    }
  }

  // Make and series (model).
  final make = _afterLabel(
    lines,
    const ['MAKE/BRAND', 'MAKE / BRAND', 'MAKE', 'BRAND'],
    exclude: const ['YEAR'],
  );
  final series = _afterLabel(lines, const ['SERIES', 'MODEL'], exclude: const ['YEAR']);
  final m = make == null ? '' : _cut(make);
  final s = series == null ? '' : _cut(series);
  String? makeModel;
  if (m.isNotEmpty && s.isNotEmpty && !s.startsWith(m)) {
    makeModel = '${_title(m)} $s';
  } else if (s.isNotEmpty) {
    makeModel = s;
  } else if (m.isNotEmpty) {
    makeModel = _title(m);
  }
  if (makeModel != null && (makeModel.length < 2 || makeModel.length > 40)) {
    makeModel = null;
  }

  // Color.
  String? color;
  final colorText = _afterLabel(lines, const ['COLOR']);
  if (colorText != null) {
    final c = _cut(colorText);
    if (c.length >= 3 && c.length <= 25 && !RegExp(r'\d').hasMatch(c)) {
      color = _title(c);
    }
  }

  // Model year.
  String? year;
  final yearText = _afterLabel(lines, const ['YEAR MODEL', 'YEAR']);
  final ym = yearText == null ? null : _yearRe.firstMatch(yearText);
  if (ym != null) {
    final y = int.parse(ym.group(1)!);
    if (y >= 1980 && y <= DateTime.now().year + 1) year = ym.group(1);
  }

  return OrcrResult(plate: plate, makeModel: makeModel, color: color, year: year);
}