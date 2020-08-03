import 'dart:convert';
import 'dart:typed_data';

/// The [BufferReader] is used to bring data back from the binary format on the
/// disk.
abstract class BufferReader {
  /// The UTF-8 decoder is used to decode Strings.
  static const utf8Decoder = Utf8Decoder();

  /// The number of bytes left in this entry.
  int get availableBytes;

  /// The number of read bytes.
  int get usedBytes;

  /// Skip n bytes.
  void skip(int bytes);

  /// Read a single byte.
  int readByte();

  /// Peek a single byte.
  int peekByte();

  /// Get a [Uint8List] view which contains the next [bytes] bytes.
  Uint8List viewBytes(int bytes);

  /// Get a [Uint8List] view which contains the next [bytes] bytes. This does
  /// not advance the internal read position.
  Uint8List peekBytes(int bytes);

  /// Read one byte as 8-bit unsigned integer.
  int readUint8();

  /// Peek one byte as 8-bit unsigned integer.
  int peekUint8();

  /// Read one byte as 8-bit signed integer.
  int readInt8();

  /// Peek one byte as 8-bit signed integer.
  int peekInt8();

  /// Read two bytes as 16-bit unsigned integer.
  int readUint16();

  /// Peek two bytes as 16-bit unsigned integer.
  int peekUint16();

  /// Read two bytes as 16-bit signed integer.
  int readInt16();

  /// Peek two bytes as 16-bit signed integer.
  int peekInt16();

  /// Read four bytes as 32-bit unsigned integer.
  int readUint32();

  /// Peek four bytes as 32-bit unsigned integer.
  int peekUint32();

  /// Read four bytes as 32-bit signed integer.
  int readInt32();

  /// Peek four bytes as 32-bit signed integer.
  int peekInt32();

  /// Read eight bytes as 64-bit signed integer.
  int readInt();

  /// Read eight bytes as 64-bit signed integer.
  int peekInt();

  /// Read eight bytes as 64-bit double.
  double readDouble();

  /// Read eight bytes as 64-bit double.
  double peekDouble();

  /// Read a boolean.
  bool readBool();

  /// Read a boolean.
  bool peekBool();

  /// Read [byteCount] bytes and decode an UTF-8 String.
  ///
  /// If [byteCount] is not provided, it is read first.
  String readString([
    int byteCount,
    Converter<List<int>, String> decoder = utf8Decoder,
  ]);

  /// Read a list of bytes with [length].
  ///
  /// If [length] is not provided, it is read first.
  Uint8List readByteList([int length]);

  /// Read a list of integers with [length].
  ///
  /// If [length] is not provided, it is read first.
  List<int> readIntList([int length]);

  /// Read a list of doubles with [length].
  ///
  /// If [length] is not provided, it is read first.
  List<double> readDoubleList([int length]);

  /// Read a list of booleans with [length].
  ///
  /// If [length] is not provided, it is read first.
  List<bool> readBoolList([int length]);

  /// Read a list of Strings with [length].
  ///
  /// If [length] is not provided, it is read first.
  List<String> readStringList([
    int length,
    Converter<List<int>, String> decoder = utf8Decoder,
  ]);

  /// Read a [BigInt].
  BigInt readBigInt();
}
