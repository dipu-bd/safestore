import 'dart:convert';
import 'dart:typed_data';

import 'package:safestore/src/utils/buffer_writer.dart';
import 'package:safestore/src/utils/extensions.dart';

class ByteBufferWriter extends BufferWriter {
  static const _initBufferSize = 256;

  Uint8List _buffer = Uint8List(_initBufferSize);

  ByteData _byteDataInstance;

  int _offset = 0;

  /// Not part of public API
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List toBytes() {
    return Uint8List.view(_buffer.buffer, 0, _offset);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  ByteData get _byteData {
    _byteDataInstance ??= ByteData.view(_buffer.buffer);
    return _byteDataInstance;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _reserveBytes(int count) {
    if (_buffer.length - _offset < count) {
      _increaseBufferSize(count);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _increaseBufferSize(int count) {
    // We will create a list in the range of 2-4 times larger than required.
    var newSize = _pow2roundup((_offset + count) * 2);
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _offset, _buffer);
    _buffer = newBuffer;
    _byteDataInstance = null;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _addBytes(Iterable<int> bytes) {
    var length = bytes.length;
    _reserveBytes(length);
    _buffer.setRange(_offset, _offset + length, bytes);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeByte(int byte) {
    byte ??= 0;
    _reserveBytes(1);
    _buffer[_offset++] = byte;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint8(int value) {
    writeByte(value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt8(int value) {
    writeUint8(value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint16(int value) {
    value ??= 0;
    _reserveBytes(2);
    _buffer[_offset++] = value;
    _buffer[_offset++] = value >> 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt16(int value) {
    writeUint16(value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value) {
    value ??= 0;
    _reserveBytes(4);
    _buffer.writeUint32(_offset, value);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt32(int value) {
    writeUint32(value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt(int value) {
    value ??= 0;
    writeDouble(value.toDouble());
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeDouble(double value) {
    value ??= 0;
    _reserveBytes(8);
    _byteData.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeBool(bool value) {
    value ??= false;
    writeByte(value ? 1 : 0);
  }

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BufferWriter.utf8Encoder,
  }) {
    value ??= '';
    var bytes = encoder.convert(value);
    if (writeByteCount) {
      writeInt32(bytes.length);
    }
    _addBytes(bytes);
  }

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) {
    bytes ??= [];
    if (writeLength) {
      writeUint32(bytes.length);
    }
    _addBytes(bytes.map((e) => e ?? 0));
  }

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) {
    writeDoubleList(list?.map((e) => e?.toDouble())?.toList());
  }

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) {
    list ??= [];
    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length * 8);
    var byteData = _byteData;
    for (var i = 0; i < length; i++) {
      byteData.setFloat64(_offset, list[i] ?? 0, Endian.little);
      _offset += 8;
    }
  }

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) {
    list ??= [];
    var length = list.length;
    if (writeLength) {
      writeUint32(length);
    }
    _reserveBytes(length);
    for (var i = 0; i < length; i++) {
      _buffer[_offset++] = (list[i] ?? false) ? 1 : 0;
    }
  }

  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BufferWriter.utf8Encoder,
  }) {
    list ??= [];
    if (writeLength) {
      writeUint32(list.length);
    }
    for (var str in list) {
      var strBytes = encoder.convert(str ?? '');
      writeUint32(strBytes.length);
      _addBytes(strBytes);
    }
  }

  @override
  void writeBigInt(BigInt value) {
    value ??= BigInt.zero;
    if (value.sign < 0) {
      value = -value;
      writeInt32(-value.bitLength);
    } else {
      writeInt32(value.bitLength);
    }
    var length = value.bitLength;
    _reserveBytes(length);
    for (var i = 0; i < length; i += 8) {
      _buffer[_offset++] = value.toUnsigned(8).toInt();
      value >>= 8;
    }
  }
}
