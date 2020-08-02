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
  final _storage = FlutterSecureStorage();

  Future<Map<String, String>> listAll() {
    return _storage.readAll();
  }

  Future<Map<String, dynamic>> open(String id) async {
    final source = await _storage.read(key: id);
    return json.decode(source);
  }

  Future<void> save(Map<String, dynamic> entity) async {
    entity[updateTimeKey] = DateTime.now().millisecondsSinceEpoch;
    log('Saving $entity', name: '$this');
    await _storage.write(
      key: entity['id'],
      value: json.encode(entity),
    );
  }

  Future<void> delete(String id) async {
    log('Deleting $id', name: '$this');
    await _storage.delete(key: id);
  }

  // ---------------------------------------------------------------------------

  Future<Uint8List> export() async {
    final Map<String, dynamic> all = await _storage.readAll();
    all[exportTimeKey] = DateTime.now().millisecondsSinceEpoch.toString();
    return utf8.encode(json.encode(all));
  }

  Future<void> import(Uint8List input) async {
    // Decipher and get the data
    final Map<String, dynamic> data = json.decode(utf8.decode(input));
    final exportTime = num.tryParse(data.remove(exportTimeKey)) ?? 0;

    // Read currently available data
    final all = await _storage.readAll();

    // Put new entries to all
    await Future.wait(data.entries.map((entry) async {
      if (!all.containsKey(entry.key)) {
        log('Adding ${entry.key}', name: '$this');
        await _storage.write(key: entry.key, value: entry.value);
      }
    }));

    // Merge updated entries
    await Future.wait(all.entries.map((entry) async {
      final updateTime = json.decode(entry.value)[updateTimeKey] as num;
      if (!data.containsKey(entry.key)) {
        // either key is a new entry or it was deleted
        if (updateTime < exportTime) {
          // since the last update time of the current entity is lower than
          // the write time of incoming data, the current entity was deleted
          log('Deleting ${entry.key}', name: '$this');
          await _storage.delete(key: entry.key);
        }
      } else {
        // the value was either modified or remained unchanged
        if (updateTime < exportTime) {
          // since the last update time of the current entity is lower than
          // the write time of incoming data, the current entity is older
          log('Updating ${entry.key}', name: '$this');
          await _storage.write(key: entry.key, value: data[entry.key]);
        }
      }
    }));
  }
}
