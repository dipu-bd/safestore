import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/services/google_drive.dart';
import 'package:safestore/src/services/serializable_store.dart';

enum StoreEvent {
  notify,
  purge,
}

class StoreState {
  bool loading = false;
  String passwordError;

  Uint8List passwordHash;
  String binName;
  File binFile;

  final labels = Set<String>();
  final notes = Map<String, SimpleNote>();
  SerializableStore<SimpleNote> storage;

  bool syncing = false;
  String syncError;
  int lastSyncTime = 0;
  bool syncPending = false;

  String lastBinMd5;
  String lastDataMd5;
  int dataVolumeSize;

  String currentLabel;

  bool get isPasswordReady => passwordHash != null && !loading;

  bool get isBinReady => storage != null && !loading;

  DateTime get lastSyncAt => DateTime.fromMillisecondsSinceEpoch(lastSyncTime);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  static StoreBloc of(BuildContext context) =>
      BlocProvider.of<StoreBloc>(context);

  final storage = FlutterSecureStorage();
  BuildContext context;

  StoreBloc(this.context) : super(StoreState()) {
    loadFromStore();
  }

  Future<void> loadFromStore() async {
    try {
      state.loading = true;
      final value = await storage.read(key: '$this');
      if (value == null || value.isEmpty) return;
      final data = json.decode(value) ?? {};
      print(data);
      state.currentLabel = data['current'];
      state.binName = data['bin'];
      (data['labels'] as List).forEach((v) => state.labels.add(v));
      state.passwordHash = Uint8List.fromList(data['password'].codeUnits);
      if (state.binName != null) {
        print('Opening bin file');
        state.binFile = await drive.findFile(
          state.binName,
          parent: drive.rootFolder,
        );
      }
      if (state.binFile != null) {
        print('creating storage');
        await _createStorage();
      }
      state.loading = false;
      notify();
    } catch (err) {
      log('$err', name: '$this');
    }
  }

  Future<void> saveToStore() async {
    final data = Map<String, dynamic>();
    data['current'] = state.currentLabel;
    data['labels'] = state.labels.toList();
    data['bin'] = state.binName;
    data['password'] = String.fromCharCodes(state.passwordHash);
    final value = json.encode(data);
    await storage.write(key: '$this', value: value);
  }

  GoogleDrive get drive {
    final auth = AuthBloc.of(context).state;
    if (auth.drive == null) {
      throw Exception('Drive was not initialized');
    }
    if (auth.rootFolderId == null) {
      throw Exception('Root folder was not found');
    }
    return auth.drive;
  }

  @override
  Stream<StoreState> mapEventToState(StoreEvent event) async* {
    switch (event) {
      case StoreEvent.notify:
        yield state;
        break;
      case StoreEvent.purge:
        state.storage?.close();
        yield StoreState();
        break;
    }
    saveToStore();
  }

  void notify() {
    add(StoreEvent.notify);
  }

  void clear() {
    add(StoreEvent.purge);
  }

  void sync() {
    state.syncPending = true;
    if (!state.syncing) syncNow();
  }

  Future<void> _createStorage() async {
    // create a storage
    log('Creating new storage', name: '$this');
    state.storage?.close();
    state.storage = SerializableStore(state.notes);
    // do a immediate sync
    await syncNow();
    if (state.syncError != null) {
      state.storage = null;
    }
    // listen to storage
    state.storage?.listener?.listen((event) {
      log(event, name: '${state.storage.runtimeType}');
      notify();
      sync();
    });
  }

  Future<bool> _checkDriveError(err) async {
    if (err is DetailedApiRequestError &&
        err.message == 'Invalid Credentials') {
      try {
        await drive.refreshToken();
        return true;
      } catch (err) {
        return false;
      }
    }
    return false;
  }

  Future<void> openBin(String plainPassword) async {
    try {
      state.loading = true;
      state.binFile = null;
      state.passwordError = null;
      notify();

      log('Generating password hash', name: '$this');
      state.passwordHash = Crypto.hashPassword(plainPassword);
      state.binName = Crypto.md5(state.passwordHash, 5);

      log('Opening bin "${state.binName}"', name: '$this');
      state.binFile = await drive.findFile(
        state.binName,
        parent: drive.rootFolder,
      );

      if (state.binFile != null) {
        await _createStorage();
      }
    } catch (err, stack) {
      if (!await _checkDriveError(err)) {
        log('$err', stackTrace: stack, name: '$this');
        state.passwordError = '$err';
      }
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> createBin(String confirmedPassword) async {
    try {
      state.loading = true;
      state.binFile = null;
      state.passwordError = null;
      notify();

      log('Generating password hash', name: '$this');
      final confirmedHash = Crypto.hashPassword(confirmedPassword);
      if (!listEquals(confirmedHash, state.passwordHash)) {
        state.passwordError = 'Confirmed password does not match';
        return;
      }

      log('Create bin "${state.binName}"', name: '$this');
      state.binFile = await drive.createFile(
        state.binName,
        parent: drive.rootFolder,
        isFile: true,
      );
      if (state.binFile == null) {
        throw Exception('No bin was created');
      }

      await _createStorage();
    } catch (err, stack) {
      if (!await _checkDriveError(err)) {
        log('$err', stackTrace: stack, name: '$this');
        state.passwordError = '$err';
      }
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> syncNow() async {
    if (state.binFile == null || state.storage == null) {
      return clear();
    }
    try {
      log('Sync started ${DateTime.now()}', name: '$this');
      state.syncing = true;
      state.syncError = null;
      state.syncPending = false;
      notify();

      // first try importing
      state.binFile = await drive.findOrCreate(
        state.binName,
        parent: drive.rootFolder,
        isFile: true,
      );
      if (state.binFile.md5Checksum != state.lastBinMd5) {
        final cipher = await drive.downloadFile(state.binFile);
        final plain = Crypto.decrypt(cipher, state.passwordHash);
        state.storage.import(plain);
        state.lastBinMd5 = state.binFile.md5Checksum;
        state.notes.values.forEach((note) => state.labels.addAll(note.labels));
      }

      // now try to exporting
      final data = state.storage.export();
      state.dataVolumeSize = data.length;
      final checksum = Crypto.md5(data);
      if (checksum != state.lastDataMd5) {
        final cipher = Crypto.encrypt(data, state.passwordHash);
        await drive.uploadFile(state.binFile, cipher);
        state.lastDataMd5 = checksum;
      }

      // set last successful sync time
      state.lastSyncTime = DateTime.now().millisecondsSinceEpoch;
    } catch (err, stack) {
      if (!await _checkDriveError(err)) {
        log('$err', stackTrace: stack, name: '$this');
        state.syncError = '$err';
      } else {
        state.syncPending = true;
      }
    } finally {
      log('Sync finished ${DateTime.now()}', name: '$this');
      state.syncing = false;
      if (state.syncPending) {
        syncNow();
      } else {
        notify();
      }
    }
  }
}
