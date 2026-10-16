const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatLongDate(DateTime d) =>
    '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

String formatTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return '$h:$m $suffix';
}

/// "Just now", "10:45 AM", "Yesterday, 3:20 PM" or "Oct 24".
String formatRelative(DateTime d) {
  final now = DateTime.now();
  if (now.difference(d).inMinutes < 1) return 'Just now';
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(now, d)) return formatTime(d);
  if (sameDay(now.subtract(const Duration(days: 1)), d)) {
    return 'Yesterday, ${formatTime(d)}';
  }
  return '${_shortMonths[d.month - 1]} ${d.day}';
}