import 'package:meta/meta.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

abstract class Serializable {
  static final int _version = 1;

  String _id;
  int _updatedAt;
  int _deletedAt;
  int _createdAt;
  bool _deleted = false;

  String get id => _id;

  bool get deleted => _deleted;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(_createdAt);

  DateTime get updatedAt => DateTime.fromMillisecondsSinceEpoch(_updatedAt);

  DateTime get deletedAt => DateTime.fromMillisecondsSinceEpoch(_deletedAt);

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
    writer.writeBool(_deleted);
    writer.writeInt(_deletedAt ?? 0);
  }

  @mustCallSuper
  void read(BufferReader reader) {
    int version = reader.readInt();
    switch (version) {
      case 1:
        _id = reader.readString();
        _createdAt = reader.readInt();
        _updatedAt = reader.readInt();
        _deleted = reader.readBool();
        _deletedAt = reader.readInt();
        break;

      default:
        throw ArgumentError('Unknown version $version');
    }
  }

  void setUpdateTime() {
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void markAsDeleted() {
    _deleted = true;
    _deletedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
