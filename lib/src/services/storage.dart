import 'dart:async';
import 'dart:typed_data';

import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

class NoteStorage {
  final _updateStream = StreamController<int>.broadcast();

  Stream<int> get stream => _updateStream.stream;

  void close() {
    _updateStream.close();
  }

  // ---------------------------------------------------------------------------

  static final int _version = 2;

  int _updatedAt = 0;
  Map<String, Serializable> _items = {};

  bool hasItem(String id) => _items.containsKey(id);

  T find<T extends Serializable>(String id) => _items[id];

  void save<T extends Serializable>(T item) {
    item.notifyUpdate();
    _items[item.id] = item;
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(_updatedAt);
  }

  void delete<T extends Serializable>(T item) {
    if (item.deleted) {
      _items.remove(item.id);
    } else {
      _items[item.id].markAsDeleted();
    }
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(_updatedAt);
  }

  void undelete<T extends Serializable>(T item) {
    _items[item.id].markAsDeleted(false);
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(_updatedAt);
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

  Iterable<SimpleNote> notes({bool includeTrash = false}) =>
      findAll((note) => includeTrash || !note.deleted);

  Set<String> labels() =>
      notes().fold(Set<String>(), (set, note) => set..addAll(note.labels));

  Iterable<SimpleNote> notesByLabel(String label,
          {bool includeTrash = false}) =>
      notes(includeTrash: includeTrash)
          .where((note) => note.labels.contains(label));

  // ---------------------------------------------------------------------------

  Uint8List export() {
    final writer = ByteBufferWriter();
    writer.writeInt(_version);
    writer.writeInt(_updatedAt);
    writer.writeInt(_items.length);
    _items.values.forEach((item) => item.write(writer));
    return writer.toBytes();
  }

  void import(Uint8List data) {
    final reader = ByteBufferReader(data);
    switch (reader.readInt()) {
      case 1:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        int length = reader.readInt();
        final entries = List<Serializable>.filled(length, null)
            .map((item) => SimpleNote()..read(reader))
            .map((e) => MapEntry(e.id, e));
        _items = Map.fromEntries(entries);
        break;

      case 2:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        _items.clear();
        int length = reader.readInt();
        for (int i = 0; i < length; ++i) {
          final note = SimpleNote()..read(reader);
          _items[note.id] = note;
        }
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }

// ---------------------------------------------------------------------------

  int get totalItems => _items.length;

  DateTime get lastSyncTime =>
      DateTime.fromMillisecondsSinceEpoch(_updatedAt ?? 0);
}
