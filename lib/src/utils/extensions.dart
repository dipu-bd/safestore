import 'dart:typed_data';

/// Not part of public API
extension StringX on String {
  /// Not part of public API
  bool get isAscii {
    for (var cu in codeUnits) {
      if (cu > 127) return false;
    }
    return true;
  }

  String toTitleCase() {
    return '${substring(0, 1).toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// Not part of public API
extension ListIntX on List<int> {
  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint32(int offset) {
    return this[offset] |
        this[offset + 1] << 8 |
        this[offset + 2] << 16 |
        this[offset + 3] << 24;
  }

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeUint32(int offset, int value) {
    this[offset] = value;
    this[offset + 1] = value >> 8;
    this[offset + 2] = value >> 16;
    this[offset + 3] = value >> 24;
  }
}

/// Not part of public API
extension Uint8ListX on Uint8List {
  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List view(int offset, int bytes) {
    return Uint8List.view(buffer, offsetInBytes + offset, bytes);
  }
}
