import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safestore/src/services/google_drive.dart';

enum AuthEvent {
  notify,
  purge,
}

class AuthState {
  bool loading = false;
  String loginError;
  GoogleDrive drive;

  bool get isLoggedIn => drive != null;

  Map<String, String> get user => drive?.user;

  Map<String, String> get authHeaders => drive?.authHeaders;

  String get userId => drive?.user['id'];

  String get email => drive?.user['email'];

  String get username => drive?.user['name'];

  String get picture => drive?.user['image'];

  String get rootFolderId => drive?.rootFolder?.id;

  @override
  int get hashCode => email.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static AuthBloc of(BuildContext context) =>
      BlocProvider.of<AuthBloc>(context);

  final storage = FlutterSecureStorage();

  AuthBloc() : super(AuthState()) {
    loadFromStore();
  }

  Future<void> loadFromStore() async {
    try {
      state.loading = true;
      final value = await storage.read(key: '$this');
      if (value == null || value.isEmpty) return;
      final data = json.decode(value) ?? {};
      final drive = GoogleDrive();
      (data['user'] as Map)?.entries?.forEach((entry) {
        drive.user[entry.key] = entry.value;
      });
      (data['auth'] as Map)?.entries?.forEach((entry) {
        drive.authHeaders[entry.key] = entry.value;
      });
      await drive.initDrive();
      state.drive = drive;
    } catch (err) {
      log('$err', name: '$this');
      state.drive = null;
    } finally {
      state.loading = false;
      notify();
    }
  }

  Future<void> saveToStore() async {
    final data = Map<String, dynamic>();
    data['user'] = state.user;
    data['auth'] = state.authHeaders;
    final value = json.encode(data);
    await storage.write(key: '$this', value: value);
  }

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    switch (event) {
      case AuthEvent.notify:
        yield state;
        break;
      case AuthEvent.purge:
        yield AuthState();
        break;
    }
    saveToStore();
  }

  void notify() {
    add(AuthEvent.notify);
  }

  void logout() {
    add(AuthEvent.purge);
  }

  void login() async {
    try {
      state.loading = true;
      state.loginError = null;
      notify();
      state.drive = await GoogleDrive.signIn();
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.loginError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }
}
