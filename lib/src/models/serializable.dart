import 'package:meta/meta.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/utils/buffer_reader.dart';
import 'package:safestore/src/utils/buffer_writer.dart';

abstract class Serializable {
  static final int _version = 1;

  String _id;
  int _updatedAt;
  int _createdAt;
  int _deletedAt;
  bool _deleted;

  String get id => _id;

  bool get deleted => _deleted ?? false;

  DateTime get createdAt => DateTime.fromMillisecondsSinceEpoch(_createdAt);

  DateTime get updatedAt => DateTime.fromMillisecondsSinceEpoch(_updatedAt);

  DateTime get deletedAt =>
      deleted ? DateTime.fromMillisecondsSinceEpoch(_deletedAt) : null;

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
    writer.writeInt(_deletedAt);
  }

  @mustCallSuper
  void read(BufferReader reader) {
    switch (reader.readInt()) {
      case 1:
        _id = reader.readString();
        _createdAt = reader.readInt();
        _updatedAt = reader.readInt();
        _deleted = reader.readBool();
        _deletedAt = reader.readInt();
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }

  void notifyUpdate() {
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  void markAsDeleted() {
    _deleted = true;
    _deletedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
