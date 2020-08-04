import 'extensions.dart';

const FILE_SIZE_SUFFIX = [' B', ' KB', ' MB', ' GB', ' TB', ' PB'];
const DURATION_PARTS = [
  [' day', ' days'],
  [' hour', ' hours'],
  [' minute', ' minutes'],
  [' second', ' seconds'],
];

String formatFileSize(num lengthInBytes, {suffixes = FILE_SIZE_SUFFIX}) {
  lengthInBytes ??= 0;
  int suffix = 1;
  var size = lengthInBytes.toDouble();
  while (size > 1024 && suffix < suffixes.length) {
    size /= 1024;
    suffix++;
  }
  return size.toStringAsFixed(2) + suffixes[suffix - 1];
}

String formatDuration(
  Duration duration, {
  String suffix = " ago",
  int maxParts = 2,
  String separator = ' ',
  List<List<String>> names = DURATION_PARTS,
}) {
  duration ??= Duration.zero;
  int days = duration.inDays;
  int hours = duration.inHours - 24 * duration.inDays;
  int minutes = duration.inMinutes - 60 * duration.inHours;
  int seconds = duration.inSeconds - 60 * duration.inMinutes;

  List<String> parts = [];
  if (days > 0) {
    parts.add('$days${names[0][days > 1 ? 1 : 0]}');
  }
  if (hours > 0) {
    parts.add('$hours${names[1][hours > 1 ? 1 : 0]}');
  }
  if (minutes > 0) {
    parts.add('$minutes${names[2][minutes > 1 ? 1 : 0]}');
  }
  if (seconds > 0 || parts.isEmpty) {
    parts.add('$seconds${names[3][seconds > 1 ? 1 : 0]}');
  }
  return parts.take(maxParts).join(separator) + (suffix ?? '');
}

String toTitleCase(String value) {
  return (value ?? '')
      .split(' ')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => e.toTitleCase())
      .join(' ');
}
