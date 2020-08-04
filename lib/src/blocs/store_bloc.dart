import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:safestore/src/blocs/auth_bloc.dart';
import 'package:safestore/src/models/simple_note.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/services/google_drive.dart';
import 'package:safestore/src/services/serializable_store.dart';

enum StoreEvent {
  sync,
  notify,
  purge,
}

class StoreState {
  bool loading = false;
  String passwordError;

  Uint8List passwordHash;
  String binName;
  File binFile;

  bool get isPasswordReady => passwordHash != null;
  bool get isBinReady => binFile?.id != null;

  final labels = Set<String>();
  final notes = Map<String, SimpleNote>();
  SerializableStore<SimpleNote> storage;

  bool syncing = false;
  String syncError;
  int lastSync = 0;
  bool syncPending = false;

  String lastBinMd5;
  String lastDataMd5;
  int dataVolumeSize;

  String currentLabel;

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  static StoreBloc of(BuildContext context) =>
      BlocProvider.of<StoreBloc>(context);

  BuildContext context;

  StoreBloc(this.context) : super(StoreState());

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
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.passwordError = '$err';
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
      if (confirmedHash != state.passwordHash) {
        throw Exception('Confirmed password does not match');
      }

      log('Create bin "${state.binName}"', name: '$this');
      state.binFile = await drive.createFile(
        state.binName,
        parent: drive.rootFolder,
      );
      if (state.binFile == null) {
        throw Exception('No bin was created');
      }

      state.storage?.close();
      state.storage = SerializableStore(state.notes);
      state.storage?.listener?.listen((event) => sync());

      await syncNow();
      state.passwordError = state.syncError;
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.passwordError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> syncNow() async {
    try {
      log('Sync started', time: DateTime.now(), name: '$this');
      state.syncing = true;
      state.syncError = null;
      notify();

      // first try importing
      state.binFile = await drive.findFile(
        state.binName,
        parent: drive.rootFolder,
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
      final checksum = Crypto.md5(data);
      if (checksum != state.lastDataMd5) {
        final cipher = Crypto.encrypt(data, state.passwordHash);
        await drive.uploadFile(state.binFile, cipher);
        state.lastDataMd5 = checksum;
        state.dataVolumeSize = cipher.length;
      }
      state.lastSync = DateTime.now().millisecondsSinceEpoch;
    } catch (err, stack) {
      if (err is ApiRequestError) {
        await drive.refreshToken();
        state.syncPending = true;
      } else {
        log('$err', stackTrace: stack, name: '$this');
        state.syncError = '$err';
      }
    } finally {
      log('Sync finished', time: DateTime.now(), name: '$this');
      state.syncing = false;
      notify();
      if (state.syncPending) {
        sync();
      }
    }
  }
}
