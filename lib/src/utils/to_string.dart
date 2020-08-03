const FILE_SIZE_SUFFIX = [' B', ' KB', ' MB', ' GB', ' TB', ' PB'];

String formatFileSize(num lengthInBytes) {
  lengthInBytes ??= 0;
  lengthInBytes = lengthInBytes.toDouble();
  int suffix = 1;
  while (lengthInBytes > 1024 && suffix < FILE_SIZE_SUFFIX.length) {
    lengthInBytes /= 1024;
    suffix++;
  }
  return lengthInBytes.toStringAsFixed(2) + FILE_SIZE_SUFFIX[suffix - 1];
}

String toTitleCase(String value) {
  return (value ?? '')
      .split(' ')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .map((e) => '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}
