class ProfileValidators {
  ProfileValidators._();

  /// UCU student ID: 8 digits that start with the entry year, e.g. 20240001.
  static String? studentId(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Student ID is required';
    if (!RegExp(r'^\d{8}$').hasMatch(v)) {
      return 'Enter your 8-digit Student ID (e.g., 20240001)';
    }
    final year = int.parse(v.substring(0, 4));
    final now = DateTime.now().year;
    if (year < 1990 || year > now) {
      return 'The first 4 digits must be your entry year (1990 to $now)';
    }
    return null;
  }
}