import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String get userId => drive?.user?.id;
  String get email => drive?.user?.email;
  String get username => drive?.user?.displayName;
  String get picture => drive?.user?.photoUrl;
  String get rootFolderId => drive?.rootFolder?.id;
  String get rootFolderName => drive?.rootFolder?.name;
  Map<String, String> get authHeaders => drive?.authHeaders;

  @override
  int get hashCode => email.hashCode;

  @override
  bool operator ==(Object other) => false;
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthState());

  static AuthBloc of(BuildContext context) =>
      BlocProvider.of<AuthBloc>(context);

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
