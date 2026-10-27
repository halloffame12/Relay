String formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 ? 0 : decimals;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatRelativeDate(DateTime date, {DateTime? reference}) {
  final now = reference ?? DateTime.now();
  final local = date.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(local.year, local.month, local.day);
  final days = today.difference(target).inDays;

  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days > 1 && days < 7) return '$days days ago';
  if (local.year == now.year) return _monthDay(local);
  return '${_monthDay(local)} ${local.year}';
}

String formatTimeAgo(DateTime date, {DateTime? reference}) {
  final now = reference ?? DateTime.now();
  final difference = now.difference(date);
  if (difference.inSeconds < 45) return 'Just now';
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes min ago';
  }
  if (difference.inHours < 24) {
    final hours = difference.inHours;
    return '$hours ${hours == 1 ? 'hr' : 'hrs'} ago';
  }
  return formatRelativeDate(date, reference: now);
}

String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_monthName(local.month)} ${local.year}';
}

String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${_monthDay(local)} ${local.year}';
}

String _monthDay(DateTime date) => '${date.day} ${_monthName(date.month)}';

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String pluralize(int count, String singular, [String? plural]) {
  return count == 1 ? singular : (plural ?? '${singular}s');
}

String titleFromFileName(String fileName) {
  final withoutExtension = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
  final cleaned = withoutExtension
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.isEmpty) return 'Untitled document';
  return cleaned
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        if (word.toUpperCase() == word && word.length <= 4) return word;
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

String formatTextScale(double scale) => '${(scale * 100).round()}%';
