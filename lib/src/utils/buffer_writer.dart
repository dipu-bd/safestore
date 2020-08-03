import 'dart:convert';

/// The [BufferWriter] is used to encode data to the binary format.
abstract class BufferWriter {
  /// The UTF-8 encoder is used to encode Strings.
  static const utf8Encoder = Utf8Encoder();

  /// Write a single byte.
  void writeByte(int byte);

  /// Write a 8-bit unsigned integer as two bytes.
  void writeUint8(int value);

  /// Write a 8-bit signed integer as two bytes.
  void writeInt8(int value);

  /// Write a 16-bit unsigned integer as two bytes.
  void writeUint16(int value);

  /// Write a 16-bit signed integer as two bytes.
  void writeInt16(int value);

  /// Write a 32-bit unsigned integer as four bytes.
  void writeUint32(int value);

  /// Write a 32-bit signed integer as four bytes.
  void writeInt32(int value);

  /// Write a [BigInt] integer.
  void writeBigInt(BigInt value);

  /// Write a 64-bit signed integer as eight bytes.
  void writeInt(int value);

  /// Write a 64-bit double as eight bytes.
  void writeDouble(double value);

  /// Write a boolean.
  void writeBool(bool value);

  /// Encode the UTF-8 String [value] and write its bytes.
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = utf8Encoder,
  });

  /// Write a list of [bytes].
  void writeByteList(List<int> bytes, {bool writeLength = true});

  /// Write a [list] of integers.
  void writeIntList(List<int> list, {bool writeLength = true});

  /// Write a [list] of doubles.
  void writeDoubleList(List<double> list, {bool writeLength = true});

  /// Write a [list] of booleans.
  void writeBoolList(List<bool> list, {bool writeLength = true});

  /// Write a [list] of Strings.
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = utf8Encoder,
  });
}
