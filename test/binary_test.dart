import 'package:flutter_test/flutter_test.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';

void main() {
  test('Check binary writer and reader', () {
    final writer = BinaryWriterImpl(null);
    writer.writeInt(0);
    writer.writeInt(2);
    writer.writeInt(-342);
    writer.writeString("str");
    writer.writeBool(true);
    writer.writeString("Hello World!");
    writer.writeDouble(20.425e-56);

    final reader = BinaryReaderImpl(writer.toBytes(), null);
    expect(reader.readInt(), 0);
    expect(reader.readInt(), 2);
    expect(reader.readInt(), -342);
    expect(reader.readString(), "str");
    expect(reader.readBool(), true);
    expect(reader.readString(), "Hello World!");
    expect(reader.readDouble(), 20.425e-56);
  });
}
