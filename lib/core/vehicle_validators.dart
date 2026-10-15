class VehicleValidators {
  VehicleValidators._();

  /// Simple check only: 5 to 8 letters or numbers (spaces and dashes allowed).
  /// Plate formats differ for cars and motorcycles, so it is not stricter.
  static String? plate(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Plate number is required';
    final compact = v.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^[A-Za-z0-9]{5,8}$').hasMatch(compact)) {
      return 'Enter a valid plate number (5 to 8 letters or numbers)';
    }
    return null;
  }

  static String? makeModel(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Make / model is required';
    if (v.length < 2) return 'Enter the vehicle make and model';
    return null;
  }

  static String? color(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Color is required';
    return null;
  }

  static String? modelYear(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Model year is required';
    final year = int.tryParse(v);
    final maxYear = DateTime.now().year + 1;
    if (year == null || v.length != 4 || year < 1980 || year > maxYear) {
      return 'Enter a valid year (1980 to $maxYear)';
    }
    return null;
  }
}