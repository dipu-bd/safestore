import 'package:flutter/material.dart';
import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

class Group extends Serializable {
  static final int _version = 2;

  String name;
  Color foreColor = Colors.white;
  Color backColor = Colors.grey[800];

  static Group get ungrouped => Group()..name = 'Ungrouped Notes';

  @override
  void write(BufferWriter writer) {
    super.write(writer);
    writer.writeInt(_version);
    writer.writeString(name);
    writer.writeUint32(foreColor.value);
    writer.writeUint32(backColor.value);
  }

  @override
  void read(BufferReader reader) {
    super.read(reader);
    switch (reader.readInt()) {
      case 1:
        name = reader.readString();
        foreColor = Color(reader.readUint32());
        break;

      case 2:
        name = reader.readString();
        foreColor = Color(reader.readUint32());
        backColor = Color(reader.readUint32());
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }
}
