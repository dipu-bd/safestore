import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/services/compress.dart';
import 'package:safestore/src/services/crypto.dart';
import 'package:safestore/src/services/google_drive.dart';
import 'package:safestore/src/services/storage.dart';

enum StoreEvent {
  notify,
  purge,
}

class StoreState {
  Uint8List passwordHash;
  String binName;
  bool loading = false;
  String passwordError;
  bool binFound = false;

  LocalStorage storage;
  bool syncing = false;
  String syncError;
  int lastSync = 0;

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
    switch (event) {
      case StoreEvent.notify:
        yield state;
        break;
      case StoreEvent.purge:
        yield StoreState();
        break;
    }
  }

  void notify() {
    add(StoreEvent.notify);
  }

  void clear() {
    add(StoreEvent.purge);
  }

  Future<void> openBin(String plainPassword) async {
    if (state.loading) return;
    try {
      state.loading = true;
      state.binFound = false;
      state.passwordError = null;
      notify();

      state.passwordHash = Crypto.hashPassword(plainPassword);
      final name = Crypto.makeHash(state.passwordHash, 5);
      state.binName = base64.encode(name).replaceAll('/', '_');
      log('Opening bin "${state.binName}"', name: '$this');
      state.storage = LocalStorage(state.binName, state.passwordHash);

      await sync();
      if (state.syncError != null) {
        state.passwordError = state.syncError;
      } else {
        state.binFound = true;
      }
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.passwordError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> sync() async {
    if (state.syncing) return;
    if (state.passwordHash == null) {
      throw Exception('Password is required');
    }

    int currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - state.lastSync < 10 * 1000) {
      log('Recent sync detected, skipping.', name: '$this');
      return;
    }
    state.lastSync = currentTime;

    try {
      state.syncing = true;
      state.syncError = null;
      notify();

      // first try importing
      var file = await GoogleDrive().getFile(state.binName);
      if (file != null) {
        final online = await GoogleDrive().downloadFile(file);
        final compressed = Crypto.decrypt(online, state.passwordHash);
        final text = Compression.uncompress(compressed); // after decrypt
        await state.storage.import(text);
      } else {
        file = await GoogleDrive().ensureFile(state.binName);
      }

      // now try to export
      final data = await state.storage.export();
      final compressed = Compression.compress(data); // before encrypt
      final offline = Crypto.encrypt(compressed, state.passwordHash);
      await GoogleDrive().uploadFile(file, offline);
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.syncError = '$err';
    } finally {
      state.syncing = false;
      notify();
    }
  }
}
