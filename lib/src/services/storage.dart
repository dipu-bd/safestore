import 'dart:async';
import 'dart:typed_data';

import 'package:safestore/src/models/group.dart';
import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

class NoteStorage {
  final _updateStream = StreamController<NoteStorage>.broadcast();

  Stream<NoteStorage> get stream => _updateStream.stream;

  void close() {
    _updateStream.close();
  }

  // ---------------------------------------------------------------------------

  static final int _version = 2;

  int _updatedAt = 0;
  Map<String, Serializable> _items = {};

  T find<T extends Serializable>(String id) => _items[id];

  void save<T extends Serializable>(T item) {
    item.notifyUpdate();
    _items[item.id] = item;
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(this);
  }

  void delete<T extends Serializable>(T note) {
    note.notifyUpdate();
    _items.remove(note.id);
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(this);
  }

  List<T> findAll<T extends Serializable>([bool Function(T item) predicate]) {
    predicate ??= (_) => true;
    return _items.values
        .where((e) => e.runtimeType == T)
        .map((e) => e as T)
        .where(predicate)
        .toList();
  }

  // ---------------------------------------------------------------------------

  List<SimpleNote> notes({bool includeTrash = false}) =>
      findAll((note) => includeTrash || !note.deleted);

  List<Group> groups({bool includeTrash = false}) =>
      findAll((group) => includeTrash || !group.deleted)
        ..insert(0, Group.ungrouped);

  List<SimpleNote> notesByGroup(String groupId, {bool includeTrash = false}) =>
      findAll((note) {
        if (!includeTrash && note.deleted) return false;
        return groupId == null || note.groups.contains(groupId);
      });

  Group findGroup(String id) => find(id) ?? Group.ungrouped;

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
        final entries = List<Serializable>.filled(length, SimpleNote())
            .map((item) => item..read(reader))
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
