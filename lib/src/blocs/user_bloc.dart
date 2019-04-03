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

  Future<bool> login(String password) async {
    try {
      final user = await StorageService.instance.checkPassword(password);
      if (user == null) {
        throw Exception('Retrieved user can not be null');
      }
      _user.sink.add(user);
      return true;
    } catch (err) {
      print('<!> login($password): $err');
    }
    return false;
  }

  Future<bool> signup(String password) async {
    try {
      final user = await StorageService.instance.createNewUser(password);
      _user.sink.add(user);
      return true;
    } catch (err) {
      print('<!> signup($password): $err');
    }
    return false;
  }
}
