import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:safestore/src/models/note.dart';

class NoteStorage {
  final _updateStream = StreamController<NoteStorage>.broadcast();

  Stream<NoteStorage> get stream => _updateStream.stream;

  void close() {
    _updateStream.close();
  }

  // ---------------------------------------------------------------------------

  static final int _version = 1;
  int _updatedAt = 0;
  final _notes = Map<String, Note>();

  Note find(String id) => _notes[id];

  List<Note> finalAll() => _notes.values.toList();

  List<Note> findByText(String query) => _notes.values.where((note) {
        return (query ?? '').trim().split(' ').any((q) {
          return q.trim().isNotEmpty &&
              (note.title.contains(q) || note.body.contains(q));
        });
      });

  void save(Note note) {
    _notes[note.id] = note;
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(this);
  }

  void delete(Note note) {
    _notes.remove(note.id);
    _updatedAt = DateTime.now().millisecondsSinceEpoch;
    _updateStream.sink.add(this);
  }

  // ---------------------------------------------------------------------------

  Uint8List export() {
    final writer = BinaryWriterImpl(null);
    writer.writeInt(_version);
    writer.writeInt(_updatedAt);
    writer.writeInt(_notes.length);
    _notes.values.forEach((note) => note.write(writer));
    return writer.toBytes();
  }

  void import(Uint8List data) {
    final reader = BinaryReaderImpl(data, null);
    int version = reader.readInt();
    switch (version) {
      case 1:
        int updateTime = reader.readInt();
        if (updateTime < _updatedAt) {
          log('Discarding older import request', name: '$this');
          return;
        }
        _notes.clear();
        int length = reader.readInt();
        for (int i = 0; i < length; ++i) {
          final note = Note()..read(reader);
          _notes[note.id] = note;
        }
        break;

      default:
        throw ArgumentError.value(version, 'version', 'Unknown version');
    }
  }
}
