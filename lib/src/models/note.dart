import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

class Note extends Serializable {
  static final int _version = 1;

  String title;
  String body;

  @override
  void write(BufferWriter writer) {
    super.write(writer);
    writer.writeInt(_version);
    writer.writeString(title);
    writer.writeString(body);
  }

  @override
  void read(BufferReader reader) {
    super.read(reader);
    switch (reader.readInt()) {
      case 1:
        title = reader.readString();
        body = reader.readString();
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }
}
