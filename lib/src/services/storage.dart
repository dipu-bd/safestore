import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:hive/hive.dart';

class LocalStorage {
  final String binId;
  final List<int> password;

  LocalStorage(this.binId, this.password);

  Future<Box<Map<String, dynamic>>> openStore() {
    return Hive.openBox(
      binId,
      encryptionKey: password,
    );
  }

  Future<List<Map<String, dynamic>>> listAll([
    bool includeTrash = false,
  ]) async {
    final store = await openStore();
    final entries = store.values.where((value) {
      return includeTrash || !(value['trashed'] ?? false);
    }).toList();
    entries.sort((a, b) => a['create_time'] - b['create_time']);
    return entries;
  }

  Future<Map<String, dynamic>> open(String id, [defaultValue]) async {
    final store = await openStore();
    return store.get(id, defaultValue: defaultValue);
  }

  Future<void> save(Map<String, dynamic> entity) async {
    log('Saving ${entity['id']}', name: '$this');
    final time = DateTime.now().millisecondsSinceEpoch;
    entity['update_time'] = time;
    final store = await openStore();
    store.put(entity['id'], entity);
  }

  Future<void> delete(String id) async {
    log('Deleting $id', name: '$this');
    final entity = await open(id);
    entity['trashed'] = true;
    await save(entity);
  }

  // ---------------------------------------------------------------------------

  Future<Uint8List> export() async {
    final all = await listAll();
    return utf8.encode(json.encode(all));
  }

  Future<void> import(Uint8List data) async {
    // Read currently available data
    final store = await openStore();

    // Decipher and get the data
    final entities = json.decode(utf8.decode(data));

    // Sync entities
    for (final item in entities) {
      final entity = item as Map<String, dynamic>;
      if (!store.containsKey(entity['id'])) {
        // A new key found. add entity to store.
        store.put(entity['id'], entity);
      } else {
        final storedEntity = store.get(entity['id']);
        if (entity['update_time'] > storedEntity['update_time']) {
          // Since new entity was updated later than stored entity, replace it
          store.put(entity['id'], entity);
        }
      }
    }

    // Take out the trash
    for (final entity in store.values) {
      if (entity['trashed'] ?? false) {
        store.delete(entity['id']);
      }
    }

    await store.compact();
  }
}
