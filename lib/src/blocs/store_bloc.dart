import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:safestore/src/services/compress.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/services/google_drive.dart';
import 'package:safestore/src/services/storage.dart';

enum StoreEvent {
  sync,
  notify,
  purge,
}

class StoreState {
  Uint8List passwordHash;
  String binName;
  bool loading = false;
  String passwordError;
  bool binFound = false;

  NoteStorage storage;
  bool syncing = false;
  String syncError;
  int lastSync = 0;
  bool syncPending = false;

  String lastDriveMd5;
  String lastDataMd5;
  int dataVolumeSize;

  String currentLabel;

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  StoreBloc() : super(StoreState());

  static StoreBloc of(BuildContext context) =>
      BlocProvider.of<StoreBloc>(context);

  @override
  Stream<StoreState> mapEventToState(StoreEvent event) async* {
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    switch (event) {
      case StoreEvent.notify:
        yield state;
        break;
      case StoreEvent.purge:
        state.storage?.close();
        yield StoreState();
        break;
      case StoreEvent.sync:
        if (!state.syncPending) break;
        if (state.syncing || currentTime - state.lastSync < 5 * 1000) {
          Future.delayed(
            Duration(milliseconds: 100),
            () => add(StoreEvent.sync),
          );
        } else {
          state.syncPending = false;
          syncNow();
        }
        break;
    }
  }

  void sync() {
    state.syncPending = true;
    add(StoreEvent.sync);
  }

  void notify() {
    add(StoreEvent.notify);
  }

  void clear() {
    add(StoreEvent.purge);
  }

  Future<void> openBin(String plainPassword) async {
    if (state.loading || state.syncing) return;
    try {
      state.loading = true;
      state.binFound = false;
      state.passwordError = null;
      notify();

      state.passwordHash = Crypto.hashPassword(plainPassword);
      state.binName = Crypto.md5(state.passwordHash, 5);

      log('Opening bin "${state.binName}"', name: '$this');
      state.storage?.close();
      state.storage = NoteStorage();
      await syncNow();

      if (state.syncError != null) {
        state.passwordError = state.syncError;
      } else {
        state.binFound = true;
        state.storage.stream.listen((event) => sync());
      }
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.passwordError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> syncNow() async {
    if (state.syncing) return;
    if (state.passwordHash == null) {
      throw Exception('Password is required');
    }

    try {
      log('Sync started', name: '$this');
      state.syncing = true;
      state.syncError = null;
      notify();

      // first try importing
      final root = await GoogleDrive().rootFolder();
      var file = await GoogleDrive().findFile(state.binName, parent: root);
      if (file == null) {
        // no such file, nothing to import. create one for export.
        file = await GoogleDrive().createFile(
          state.binName,
          parent: root,
          isFile: true,
        );
      } else {
        if (file.md5Checksum != state.lastDriveMd5) {
          // read file and import
          final cipher = await GoogleDrive().downloadFile(file);
          final plain = Crypto.decrypt(cipher, state.passwordHash);
          final data = Compression.uncompress(plain); // after decrypt
          state.storage.import(data);
          state.lastDriveMd5 = file.md5Checksum;
        }
      }

      // now try to exporting
      final data = state.storage.export();
      final checksum = Crypto.md5(data);
      if (checksum != state.lastDataMd5) {
        final compressed = Compression.compress(data); // before encrypt
        final cipher = Crypto.encrypt(compressed, state.passwordHash);
        await GoogleDrive().uploadFile(file, cipher);
        state.lastDataMd5 = checksum;
        state.dataVolumeSize = cipher.length;
      }
    } catch (err, stack) {
      if (err is ApiRequestError) {
        GoogleDrive().signOut();
        return sync();
      }
      log('$err', stackTrace: stack, name: '$this');
      state.syncError = '$err';
    } finally {
      log('Sync ended', name: '$this');
      state.lastSync = DateTime.now().millisecondsSinceEpoch;
      state.syncing = false;
      add(StoreEvent.sync);
      notify();
    }
  }
}
