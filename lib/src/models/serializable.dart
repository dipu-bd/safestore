import 'package:meta/meta.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

abstract class Serializable {
  static final int _version = 1;

  String _id;
  int _updatedAt;
  int _createdAt;
  int _archivedAt;
  bool _archived;

  String get id => _id;

  bool get isArchived => _archived ?? false;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(_createdAt);

  DateTime get updatedAt => DateTime.fromMillisecondsSinceEpoch(_updatedAt);

  DateTime get deletedAt =>
      isArchived ? DateTime.fromMillisecondsSinceEpoch(_archivedAt) : null;

  Serializable() : this.id(Crypto.generateId());

  Serializable.id(this._id)
      : _createdAt = DateTime.now().millisecondsSinceEpoch,
        _updatedAt = DateTime.now().millisecondsSinceEpoch;

  @mustCallSuper
  void write(BufferWriter writer) {
    writer.writeInt(_version);
    writer.writeString(_id);
    writer.writeInt(_createdAt);
    writer.writeInt(_updatedAt);
    writer.writeBool(_archived);
    writer.writeInt(_archivedAt);
  }

  @mustCallSuper
  void read(BufferReader reader) {
    switch (reader.readInt()) {
      case 1:
        _id = reader.readString();
        _createdAt = reader.readInt();
        _updatedAt = reader.readInt();
        _archived = reader.readBool();
        _archivedAt = reader.readInt();
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }

  void notifyUpdate() {
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void setArchived([bool archived = true]) {
    _archived = archived;
    if (archived) {
      _archivedAt = DateTime.now().millisecondsSinceEpoch;
    } else {
      _updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
  }

  void copyFrom<T extends Serializable>(T other) {
    final writer = ByteBufferWriter();
    other.write(writer);
    final reader = ByteBufferReader(writer.toBytes());
    read(reader);
  }

  bool isNew() => (_createdAt - _updatedAt).abs() < 10;
}
