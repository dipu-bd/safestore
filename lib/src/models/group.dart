import 'package:flutter/painting.dart';
import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

class Group extends Serializable {
  static final int _version = 1;

  String name;
  Color color;

  static final Group ungrouped = Group()..name = 'Ungrouped';

  @override
  void write(BufferWriter writer) {
    super.write(writer);
    writer.writeInt(_version);
    writer.writeString(name);
    writer.writeUint32(color.value);
  }

  @override
  void read(BufferReader reader) {
    super.read(reader);
    switch (reader.readInt()) {
      case 1:
        name = reader.readString();
        color = Color(reader.readUint32());
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }
}
