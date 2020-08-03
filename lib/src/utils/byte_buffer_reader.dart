import 'dart:convert';
import 'dart:typed_data';

import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/extensions.dart';

class ByteBufferReader extends BufferReader {
  final Uint8List _buffer;
  final ByteData _byteData;

  int _bufferLimit;
  int _offset = 0;

  /// Not part of public API
  ByteBufferReader(this._buffer, [int bufferLength])
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes),
        _bufferLimit = bufferLength ?? _buffer.length;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int get availableBytes => _bufferLimit - _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int get usedBytes => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _requireBytes(int bytes) {
    if (_offset + bytes > _bufferLimit) {
      throw RangeError('Not enough bytes available.');
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void skip(int bytes) {
    _requireBytes(bytes);
    _offset += bytes;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readByte() {
    _requireBytes(1);
    return _buffer[_offset++];
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekByte() {
    _requireBytes(1);
    return _buffer[_offset];
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List viewBytes(int bytes) {
    _requireBytes(bytes);
    _offset += bytes;
    return _buffer.view(_offset - bytes, bytes);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List peekBytes(int bytes) {
    _requireBytes(bytes);
    return _buffer.view(_offset, bytes);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint8() {
    return readByte();
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekUint8() {
    return peekByte();
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt8() {
    return readUint8().toSigned(8);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekInt8() {
    return peekUint8().toSigned(8);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint16() {
    _requireBytes(2);
    _offset += 2;
    return _buffer[_offset - 2] | _buffer[_offset - 1] << 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekUint16() {
    _requireBytes(2);
    return _buffer[_offset] | _buffer[_offset + 1] << 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt16() {
    return readUint16().toSigned(16);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekInt16() {
    return peekUint16().toSigned(16);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint32() {
    _requireBytes(4);
    _offset += 4;
    return _buffer.readUint32(_offset - 4);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekUint32() {
    _requireBytes(4);
    return _buffer.readUint32(_offset);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt32() {
    return readUint32().toSigned(32);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekInt32() {
    return peekUint32().toSigned(32);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt() {
    return readDouble().toInt();
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int peekInt() {
    return peekDouble().toInt();
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double readDouble() {
    var value = peekDouble();
    _offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double peekDouble() {
    _requireBytes(8);
    return _byteData.getFloat64(_offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  bool readBool() {
    return readByte() > 0;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  bool peekBool() {
    return peekByte() > 0;
  }

  @override
  String readString(
      [int byteCount,
      Converter<List<int>, String> decoder = BufferReader.utf8Decoder]) {
    byteCount ??= readUint32();
    var view = viewBytes(byteCount);
    return decoder.convert(view);
  }

  @override
  Uint8List readByteList([int length]) {
    length ??= readUint32();
    _requireBytes(length);
    var byteList = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return byteList;
  }

  @override
  List<int> readIntList([int length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var byteData = _byteData;
    var list = <int>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = byteData.getFloat64(_offset, Endian.little).toInt();
      _offset += 8;
    }
    return list;
  }

  @override
  List<double> readDoubleList([int length]) {
    length ??= readUint32();
    _requireBytes(length * 8);
    var byteData = _byteData;
    var list = <double>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = byteData.getFloat64(_offset, Endian.little);
      _offset += 8;
    }
    return list;
  }

  @override
  List<bool> readBoolList([int length]) {
    length ??= readUint32();
    _requireBytes(length);
    var list = <bool>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = _buffer[_offset++] != 0;
    }
    return list;
  }

  @override
  List<String> readStringList(
      [int length,
      Converter<List<int>, String> decoder = BufferReader.utf8Decoder]) {
    length ??= readUint32();
    var list = <String>[]..length = length;
    for (var i = 0; i < length; i++) {
      list[i] = readString(null, decoder);
    }
    return list;
  }

  @override
  BigInt readBigInt() {
    var bitLength = readInt32();
    var sign = bitLength.sign;
    if (sign < 0) {
      bitLength = -bitLength;
    }
    _requireBytes((bitLength / 8).ceil());
    var value = BigInt.zero;
    for (int i = 0; i < bitLength; i += 8) {
      value |= BigInt.from(_buffer[_offset++]) << i;
    }
    if (sign < 0) {
      value = -value;
    }
    return value;
  }
}
