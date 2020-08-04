import 'dart:async';
import 'dart:typed_data';

import 'package:safestore/src/models/serializable.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/services/compress.dart';
import 'package:safestore/src/utils/byte_buffer_reader.dart';
import 'package:safestore/src/utils/byte_buffer_writer.dart';

class SerializableStore<T extends Serializable> {
  static final int _version = 3;
  static const TYPE_REGISTRY = const <Type>[
    SimpleNote,
  ];

  int _updatedAt = 0;
  final Map<String, T> items;
  final _statusManager = StreamController<String>(sync: true);

  SerializableStore(this.items);

  Stream<String> get listener => _statusManager.stream;

  void close() {
    _statusManager.close();
  }

  void notify([String status]) {
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _statusManager.sink.add(status);
  }

  // ---------------------------------------------------------------------------

  DateTime get lastUpdatedAt =>
      DateTime.fromMillisecondsSinceEpoch(_updatedAt ?? 0);

  T getItem(String id) => items[id];

  bool hasItem(String id) => items.containsKey(id);

  Iterable<T> find([bool Function(T item) predicate]) {
    return items.values
        .where((e) => e.runtimeType == T)
        .where(predicate ?? (_) => true);
  }

  void save(T item) {
    item.notifyUpdate();
    items[item.id] = item;
    notify('Saved ${item.id}');
  }

  void delete(T item) {
    if (item.isArchived) {
      items.remove(item.id);
      notify('Deleted ${item.id}');
    } else {
      items[item.id].setArchived();
      notify('Archived ${item.id}');
    }
  }

  void restore(T item) {
    items[item.id].setArchived(false);
    notify('Restored ${item.id}');
  }

  // ---------------------------------------------------------------------------

  Uint8List export() {
    final writer = ByteBufferWriter();
    writer.writeInt(_version);
    writer.writeInt(_updatedAt);
    writer.writeUint32(items.length);
    items.values.forEach((item) {
      int index = TYPE_REGISTRY.indexOf(item.runtimeType);
      if (index == -1) {
        throw Exception('Unregistered type: ${item.runtimeType}');
      }
      writer.writeUint32(index);
      item.write(writer);
    });
    final data = writer.toBytes();
    return Compression.compress(data);
  }

  void import(Uint8List data) {
    final uncompressed = Compression.uncompress(data);
    final reader = ByteBufferReader(uncompressed);
    switch (reader.readInt()) {
      case 1:
      case 2:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        int length = reader.readInt();
        var entries = List<Serializable>();
        for (int i = 0; i < length; ++i) {
          entries.add(SimpleNote()..read(reader));
        }
        items.clear();
        items.addEntries(entries.map((e) => MapEntry(e.id, e)));
        break;

      case 3:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) return; // imported data is older
        int length = reader.readUint32();
        var entries = List<Serializable>();
        for (int i = 0; i < length; ++i) {
          int type = reader.readUint32();
          switch (TYPE_REGISTRY[type]) {
            case SimpleNote:
              entries.add(SimpleNote()..read(reader));
              break;
            default:
              throw Exception('Unknown type id: $type');
          }
        }
        items.clear();
        items.addEntries(entries.map((e) => MapEntry(e.id, e)));
        break;

      default:
        throw ArgumentError('Unknown version');
    }
  }
}
