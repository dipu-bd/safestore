import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:safestore/src/models/user.dart';
import 'package:safestore/src/services/StorageService.dart';
import 'bloc_provider.dart';

class UserBloc extends BlocBase {
  final _user = BehaviorSubject<User>.seeded(null);

  static UserBloc of(BuildContext context) => BlocProvider.of(context);

  @override
  void initState(BuildContext context) {
    //
  }

  @override
  void dispose() {
    _user.close();
  }

  ValueObservable<User> get user => _user.stream;

  Future<void> signin(String password) async {
    try {
      final user = await StorageService.instance.checkPassword(password);
      if (user == null) {
        throw Exception('Retrieved user can not be null');
      }
      _user.sink.add(user);
    } catch (err) {
      print('<!> login($password): $err');
      throw Exception('Failed to login\n$err');
    }
  }

  Future<void> signup(String password) async {
    try {
      final user = await StorageService.instance.createNewUser(password);
      _user.sink.add(user);
    } catch (err) {
      print('<!> signup($password): $err');
      throw Exception('Failed to create new user\n$err');
    }
  }

  void signout() {
    _user.sink.add(null);
  }
}
