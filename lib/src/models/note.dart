import 'package:hive/hive.dart';
import 'package:safestore/src/models/serializable.dart';

class Note extends Serializable {
  static final int _version = 1;

  String title;
  String body;

  @override
  void write(BinaryWriter writer) {
    super.write(writer);
    writer.writeInt(_version);
    writer.writeString(title);
    writer.writeString(body);
  }

  @override
  void read(BinaryReader reader) {
    super.read(reader);
    int version = reader.readInt();
    switch (version) {
      case 1:
        title = reader.readString();
        body = reader.readString();
        break;

      default:
        throw ArgumentError.value(version, 'version', 'Unknown version');
    }
  }
}
