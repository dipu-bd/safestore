import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _instance = SecureStorage._init();

  factory SecureStorage() => _instance;

  SecureStorage._init();

  // ---------------------------------------------------------------------------

  static final exportTimeKey = 'export_time';
  static final updateTimeKey = 'update_time';
  final _store = FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> listAll([
    bool includeTrash = false,
  ]) async {
    final Map<String, String> all = await _store.readAll();
    final entries = List<Map<String, dynamic>>();
    all.keys.forEach((key) {
      if (key == updateTimeKey) return;
      final Map<String, dynamic> value = json.decode(all[key]);
      if (includeTrash || !(value['trashed'] ?? false)) {
        entries.add(value);
      }
    });
    entries.sort((a, b) => a['create_time'] - b['create_time']);
    return entries;
  }

  Future<Map<String, dynamic>> open(String id) async {
    final source = await _store.read(key: id);
    return json.decode(source);
  }

  Future<void> save(Map<String, dynamic> entity) async {
    final time = DateTime.now().millisecondsSinceEpoch;
    entity[updateTimeKey] = time;
    log('Saving $entity', name: '$this');
    await _store.write(
      key: entity['id'],
      value: json.encode(entity),
    );
    await _store.write(
      key: updateTimeKey,
      value: time.toString(),
    );
  }

  Future<void> delete(String id) async {
    log('Deleting $id', name: '$this');
    final entity = await open(id);
    entity['trashed'] = true;
    await save(entity);
  }

  // ---------------------------------------------------------------------------

  Future<Uint8List> export() async {
    log('Exporting at ${DateTime.now()}', name: '$this');
    final Map<String, dynamic> data = {
      'all': await listAll(),
      exportTimeKey: DateTime.now().millisecondsSinceEpoch,
    };
    return utf8.encode(json.encode(data));
  }

  Future<void> import(Uint8List input) async {
    // Decipher and get the data
    final Map<String, dynamic> data = json.decode(utf8.decode(input));
    final exportTime = (data[exportTimeKey] as num) ?? 0;
    final exportDate = DateTime.fromMillisecondsSinceEpoch(exportTime);
    log('Importing data with export time $exportDate', name: '$this');

    // The entity list to import
    final Map<String, dynamic> entities = Map.fromEntries(
      (data['all'] as List ?? []).map((e) => MapEntry(e['id'], e)),
    );

    // Read currently available data
    final all = await _store.readAll();
    final updateTime = num.parse(await _store.read(key: updateTimeKey) ?? '0');
    final updateDate = DateTime.fromMillisecondsSinceEpoch(updateTime);
    log('Last update time $updateDate', name: '$this');

    // Merge updated entries
    await Future.wait(all.entries.map((entry) async {
      if (entry.key == updateTimeKey) return;
      if (!entities.containsKey(entry.key)) {
        // either the entry is new or deleted
        if (updateTime < exportTime) {
          // since the last update time is lower than the export time,
          // the current entity was deleted
          await _store.delete(key: entry.key);
          entities.remove(entry.key);
        }
      } else {
        // the value was either modified or remained unchanged
        if (updateTime < exportTime) {
          // since the last update time is lower than the export time,
          // the current entity was modified
          await _store.write(
            key: entry.key,
            value: json.encode(entities[entry.key]),
          );
        }
      }
    }));

    // Add all new entities
    await Future.wait(entities.entries.map((entry) async {
      if (!all.containsKey(entry.key)) {
        await save(entry.value);
      }
    }));
  }
}
