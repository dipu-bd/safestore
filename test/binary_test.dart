import 'package:flutter_test/flutter_test.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

void main() {
  test('Check write and read for booleans', () {
    final writer = ByteBufferWriter();
    writer.writeBool(null);
    writer.writeBool(true);
    writer.writeBool(false);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekBool(), false);
    expect(reader.readBool(), false);
    expect(reader.peekBool(), true);
    expect(reader.readBool(), true);
    expect(reader.peekBool(), false);
    expect(reader.readBool(), false);
  });

  test('Check write and read for bytes', () {
    final writer = ByteBufferWriter();
    writer.writeByte(null);
    writer.writeByte(0);
    writer.writeByte(2);
    writer.writeByte(-32);
    writer.writeByte(3452);
    writer.writeByte(-3452);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekByte(), 0);
    expect(reader.readByte(), 0);
    expect(reader.peekByte(), 0);
    expect(reader.readByte(), 0);
    expect(reader.peekByte(), 2);
    expect(reader.readByte(), 2);
    expect(reader.peekByte(), (-32).toUnsigned(8));
    expect(reader.readByte(), (-32).toUnsigned(8));
    expect(reader.readByte(), (3452).toUnsigned(8));
    expect(reader.readByte(), (-3452).toUnsigned(8));
  });

  test('Check write and read for 8 bit integer', () {
    final writer = ByteBufferWriter();
    writer.writeUint8(null);
    writer.writeUint8(0);
    writer.writeUint8(2);
    writer.writeUint8(-32);
    writer.writeUint8(3452);
    writer.writeUint8(-3452);

    writer.writeInt8(0);
    writer.writeInt8(2);
    writer.writeInt8(-32);
    writer.writeInt8(3452);
    writer.writeInt8(-3452);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekUint8(), 0);
    expect(reader.readUint8(), 0);
    expect(reader.peekUint8(), 0);
    expect(reader.readUint8(), 0);
    expect(reader.peekUint8(), 2);
    expect(reader.readUint8(), 2);
    expect(reader.peekUint8(), (-32).toUnsigned(8));
    expect(reader.readUint8(), (-32).toUnsigned(8));
    expect(reader.readUint8(), (3452).toUnsigned(8));
    expect(reader.readUint8(), (-3452).toUnsigned(8));

    expect(reader.peekInt8(), 0);
    expect(reader.readInt8(), 0);
    expect(reader.peekInt8(), 2);
    expect(reader.readInt8(), 2);
    expect(reader.peekInt8(), -32);
    expect(reader.readInt8(), -32);
    expect(reader.readInt8(), (3452).toSigned(8));
    expect(reader.readInt8(), (-3452).toSigned(8));
  });

  test('Check write and read for 32 bit integer', () {
    final writer = ByteBufferWriter();
    writer.writeUint32(null);
    writer.writeUint32(0);
    writer.writeUint32(2);
    writer.writeUint32(-32);
    writer.writeUint32(1234567890123);
    writer.writeUint32(-1234567890123);

    writer.writeInt32(null);
    writer.writeInt32(0);
    writer.writeInt32(2);
    writer.writeInt32(-32);
    writer.writeInt32(1234567890123);
    writer.writeInt32(-1234567890123);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekUint32(), 0);
    expect(reader.readUint32(), 0);
    expect(reader.peekUint32(), 0);
    expect(reader.readUint32(), 0);
    expect(reader.peekUint32(), 2);
    expect(reader.readUint32(), 2);
    expect(reader.peekUint32(), (-32).toUnsigned(32));
    expect(reader.readUint32(), (-32).toUnsigned(32));
    expect(reader.readUint32(), (1234567890123).toUnsigned(32));
    expect(reader.readUint32(), (-1234567890123).toUnsigned(32));

    expect(reader.peekInt32(), 0);
    expect(reader.readInt32(), 0);
    expect(reader.peekInt32(), 0);
    expect(reader.readInt32(), 0);
    expect(reader.peekInt32(), 2);
    expect(reader.readInt32(), 2);
    expect(reader.peekInt32(), -32);
    expect(reader.readInt32(), -32);
    expect(reader.readInt32(), (1234567890123).toSigned(32));
    expect(reader.readInt32(), (-1234567890123).toSigned(32));
  });

  test('Check write and read for integer', () {
    final writer = ByteBufferWriter();
    writer.writeInt(null);
    writer.writeInt(0);
    writer.writeInt(2);
    writer.writeInt(-32);
    writer.writeInt(1234567890125345);
    writer.writeInt(-1234567890125345);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekInt(), 0);
    expect(reader.readInt(), 0);
    expect(reader.peekInt(), 0);
    expect(reader.readInt(), 0);
    expect(reader.peekInt(), 2);
    expect(reader.readInt(), 2);
    expect(reader.peekInt(), -32);
    expect(reader.readInt(), -32);
    expect(reader.readInt(), 1234567890125345);
    expect(reader.readInt(), -1234567890125345);
  });

  test('Check write and read for double', () {
    final writer = ByteBufferWriter();
    writer.writeDouble(null);
    writer.writeDouble(0);
    writer.writeDouble(2);
    writer.writeDouble(-32);
    writer.writeDouble(1234567890125345);
    writer.writeDouble(-1234567890125345);
    writer.writeDouble(1.5546);
    writer.writeDouble(-1.5546);
    writer.writeDouble(1.5546e-545);
    writer.writeDouble(-1.5546e564);
    writer.writeDouble(15546e-545);
    writer.writeDouble(-15546e564);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.peekDouble(), 0);
    expect(reader.readDouble(), 0);
    expect(reader.peekDouble(), 0);
    expect(reader.readDouble(), 0);
    expect(reader.peekDouble(), 2);
    expect(reader.readDouble(), 2);
    expect(reader.peekDouble(), -32);
    expect(reader.readDouble(), -32);
    expect(reader.readDouble(), 1234567890125345);
    expect(reader.readDouble(), -1234567890125345);
    expect(reader.readDouble(), 1.5546);
    expect(reader.readDouble(), -1.5546);
    expect(reader.readDouble(), 1.5546e-545);
    expect(reader.readDouble(), -1.5546e564);
    expect(reader.readDouble(), 15546e-545);
    expect(reader.readDouble(), -15546e564);
  });

  test('Check write and read for big integer', () {
    final writer = ByteBufferWriter();
    writer.writeBigInt(null);
    writer.writeBigInt(BigInt.zero);
    writer.writeBigInt(-BigInt.zero);
    writer.writeBigInt(BigInt.one);
    writer.writeBigInt(-BigInt.one);
    writer.writeBigInt(BigInt.two);
    writer.writeBigInt(-BigInt.two);
    writer.writeBigInt(BigInt.from(2).pow(100));
    writer.writeBigInt(-BigInt.from(2).pow(200));

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readBigInt(), BigInt.zero);
    expect(reader.readBigInt(), BigInt.zero);
    expect(reader.readBigInt(), BigInt.zero);
    expect(reader.readBigInt(), BigInt.one);
    expect(reader.readBigInt(), -BigInt.one);
    expect(reader.readBigInt(), BigInt.two);
    expect(reader.readBigInt(), -BigInt.two);
    writer.writeBigInt(BigInt.from(2).pow(100));
    writer.writeBigInt(-BigInt.from(2).pow(200));
  });

  test('Check write and read for string', () {
    final writer = ByteBufferWriter();
    writer.writeString(null);
    writer.writeString('');
    writer.writeString('1');
    writer.writeString('hello there');

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readString(), '');
    expect(reader.readString(), '');
    expect(reader.readString(), '1');
    expect(reader.readString(), 'hello there');
  });

  test('Check write and read for bool list', () {
    final writer = ByteBufferWriter();
    writer.writeBoolList(null);
    writer.writeBoolList([]);
    writer.writeBoolList([true]);
    writer.writeBoolList([false]);
    writer.writeBoolList([false, false]);
    writer.writeBoolList([false, true, true, true, false]);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readBoolList(), []);
    expect(reader.readBoolList(), []);
    expect(reader.readBoolList(), [true]);
    expect(reader.readBoolList(), [false]);
    expect(reader.readBoolList(), [false, false]);
    expect(reader.readBoolList(), [false, true, true, true, false]);
  });

  test('Check write and read for byte list', () {
    final writer = ByteBufferWriter();
    writer.writeByteList(null);
    writer.writeByteList([]);
    writer.writeByteList([0]);
    writer.writeByteList([3]);
    writer.writeByteList([-3]);
    writer.writeByteList([0, 0]);
    writer.writeByteList([2, 4, 4, 2, 4, 5, 234]);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readByteList(), []);
    expect(reader.readByteList(), []);
    expect(reader.readByteList(), [0]);
    expect(reader.readByteList(), [3]);
    expect(reader.readByteList(), [(-3).toUnsigned(8)]);
    expect(reader.readByteList(), [0, 0]);
    expect(reader.readByteList(), [2, 4, 4, 2, 4, 5, 234]);
  });

  test('Check write and read for integer list', () {
    final writer = ByteBufferWriter();
    writer.writeIntList(null);
    writer.writeIntList([]);
    writer.writeIntList([0]);
    writer.writeIntList([3]);
    writer.writeIntList([-3]);
    writer.writeIntList([0, 0]);
    writer.writeIntList([2, -4, 4, -2, 4, 5, 234, 23049823]);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readIntList(), []);
    expect(reader.readIntList(), []);
    expect(reader.readIntList(), [0]);
    expect(reader.readIntList(), [3]);
    expect(reader.readIntList(), [-3]);
    expect(reader.readIntList(), [0, 0]);
    expect(reader.readIntList(), [2, -4, 4, -2, 4, 5, 234, 23049823]);
  });

  test('Check write and read for double list', () {
    final writer = ByteBufferWriter();
    writer.writeDoubleList(null);
    writer.writeDoubleList([]);
    writer.writeDoubleList([null]);
    writer.writeDoubleList([0]);
    writer.writeDoubleList([3]);
    writer.writeDoubleList([-3]);
    writer.writeDoubleList([3.55123]);
    writer.writeDoubleList([-3e-55123]);
    writer.writeDoubleList([0, 0]);
    writer.writeDoubleList([2, -4.5, 4e-88, -2e5411, 4, 23049823]);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readDoubleList(), []);
    expect(reader.readDoubleList(), []);
    expect(reader.readDoubleList(), [0]);
    expect(reader.readDoubleList(), [0]);
    expect(reader.readDoubleList(), [3]);
    expect(reader.readDoubleList(), [-3]);
    expect(reader.readDoubleList(), [3.55123]);
    expect(reader.readDoubleList(), [-3e-55123]);
    expect(reader.readDoubleList(), [0, 0]);
    expect(reader.readDoubleList(), [2, -4.5, 4e-88, -2e5411, 4, 23049823]);
  });

  test('Check write and read for string list', () {
    final writer = ByteBufferWriter();
    writer.writeStringList([]);
    writer.writeStringList(null);
    writer.writeStringList(['']);
    writer.writeStringList([null]);
    writer.writeStringList(["hello there!"]);

    final reader = ByteBufferReader(writer.toBytes());
    expect(reader.readStringList(), []);
    expect(reader.readStringList(), []);
    expect(reader.readStringList(), ['']);
    expect(reader.readStringList(), ['']);
    expect(reader.readStringList(), ["hello there!"]);
  });
}
