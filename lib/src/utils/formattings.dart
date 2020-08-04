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
  DateTime time, {
  String suffix = " ago",
  int maxParts = 2,
  parts = DURATION_PARTS,
}) {
  final diff = DateTime.now().difference(time);
  List<String> parts = [];
  if (diff.inDays > 0) {
    parts.add('${diff.inDays}${parts[diff.inDays > 1 ? 1 : 0]}');
  }
  if (diff.inHours > 0) {
    parts.add('${diff.inHours}${parts[diff.inHours > 1 ? 1 : 0]}');
  }
  if (diff.inMinutes > 0) {
    parts.add('${diff.inMinutes}${parts[diff.inMinutes > 1 ? 1 : 0]}');
  }
  if (diff.inSeconds > 0) {
    parts.add('${diff.inSeconds}${parts[diff.inSeconds > 1 ? 1 : 0]}');
  }
  return parts.take(maxParts).join(' ') + (suffix ?? '');
}

String toTitleCase(String value) {
  return (value ?? '')
      .split(' ')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => e.toTitleCase())
      .join(' ');
}
