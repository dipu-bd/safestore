import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safestore/src/services/google_drive.dart';

enum AuthEvent {
  notify,
  purge,
}

class AuthState {
  bool loading = false;
  String loginError;
  String email;
  String username;
  String picture;
  String passwordHash;

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
      final user = await GoogleDrive().signIn();
      state.email = user.email;
      state.username = user.displayName;
      state.picture = user.photoUrl;
    } catch (err, stack) {
      log('$err', stackTrace: stack, name: '$this');
      state.loginError = '$err';
    } finally {
      state.loading = false;
      notify();
    }
  }
}
