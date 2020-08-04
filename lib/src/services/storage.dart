import 'dart:async';
import 'dart:typed_data';

import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

class NoteStorage {
  final _updateStream = StreamController<Serializable>.broadcast();

  Stream<Serializable> get stream => _updateStream.stream;

  void close() {
    _updateStream.close();
  }

  // ---------------------------------------------------------------------------

  static final int _version = 3;

  int _updatedAt = 0;
  final _labels = Set<String>();
  Map<String, Serializable> _items = {};
  final List<Type> _typeRegistry = [SimpleNote];

  bool hasItem(String id) => _items.containsKey(id);

  T find<T extends Serializable>(String id) => _items[id];

  void save<T extends Serializable>(T item) {
    item.notifyUpdate();
    _items[item.id] = item;
    if (item is SimpleNote) {
      _labels.addAll(item.labels);
    }
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(item);
  }

  void delete<T extends Serializable>(T item) {
    if (item.deleted) {
      _items.remove(item.id);
    } else {
      _items[item.id].markAsDeleted();
    }
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(item);
  }

  void restore<T extends Serializable>(T item) {
    _items[item.id].markAsDeleted(false);
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(item);
  }

  Iterable<T> findAll<T extends Serializable>(
      [bool Function(T item) predicate]) {
    predicate ??= (_) => true;
    return _items.values
        .where((e) => e.runtimeType == T)
        .map((e) => e as T)
        .where(predicate);
  }

  // ---------------------------------------------------------------------------

  Uint8List export() {
    final writer = ByteBufferWriter();
    writer.writeInt(_version);
    writer.writeInt(_updatedAt);
    writer.writeUint32(_items.length);
    _items.values.forEach((item) {
      writer.writeUint32(_typeRegistry.indexOf(item.runtimeType));
      item.write(writer);
    });
    return writer.toBytes();
  }

  void import(Uint8List data) {
    final reader = ByteBufferReader(data);
    switch (reader.readInt()) {
      case 1:
      case 2:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        int length = reader.readInt();
        var entries = List<Serializable>();
        for (int i = 0; i < length; ++i) {
          final note = SimpleNote()..read(reader);
          _labels.addAll(note.labels);
          entries.add(note);
        }
        _items = Map.fromEntries(entries.map((e) => MapEntry(e.id, e)));
        break;

      case 3:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        int length = reader.readUint32();
        var entries = List<Serializable>();
        for (int i = 0; i < length; ++i) {
          int type = reader.readUint32();
          switch (_typeRegistry[type]) {
            case SimpleNote:
              final note = SimpleNote()..read(reader);
              _labels.addAll(note.labels);
              entries.add(note);
          }
        }
        _items = Map.fromEntries(entries.map((e) => MapEntry(e.id, e)));
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }

  // ---------------------------------------------------------------------------

  int get totalItems => _items.length;

  DateTime get lastSyncTime =>
      DateTime.fromMillisecondsSinceEpoch(_updatedAt ?? 0);

  Set<String> labels() => _labels;

  void addLabel(String label) => _labels.add(label);

  Iterable<SimpleNote> notes() => findAll((note) => !note.deleted);

  Iterable<SimpleNote> archivedNotes() => findAll((note) => note.deleted);
}
