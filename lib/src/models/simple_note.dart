import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

class SimpleNote extends Serializable {
  static final int _version = 2;

  String title;
  String body;
  final groups = <String>[''].toSet();

  @override
  void write(BufferWriter writer) {
    super.write(writer);
    writer.writeInt(_version);
    writer.writeString(title);
    writer.writeString(body);
    writer.writeStringList(groups.toList());
  }

  @override
  void read(BufferReader reader) {
    super.read(reader);
    switch (reader.readInt()) {
      case 1:
        title = reader.readString();
        body = reader.readString();
        break;

      case 2:
        title = reader.readString();
        body = reader.readString();
        var list = reader.readStringList();
        groups.clear();
        groups.addAll(list);
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }
}
