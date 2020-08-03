const FILE_SIZE_SUFFIX = [' B', ' KB', ' MB', ' GB', ' TB', ' PB'];

String formatFileSize(double lengthInBytes) {
  lengthInBytes ??= 0;
  int suffix = 1;
  while (lengthInBytes > 1024 && suffix < FILE_SIZE_SUFFIX.length) {
    lengthInBytes /= 1024;
    suffix++;
  }
  if (lengthInBytes - lengthInBytes.round() < 1e-3) {
    return lengthInBytes.round().toString() + FILE_SIZE_SUFFIX[suffix - 1];
  } else {
    return lengthInBytes.toStringAsPrecision(2) + FILE_SIZE_SUFFIX[suffix - 1];
  }
}
