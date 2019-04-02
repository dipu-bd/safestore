import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safestore/src/models/user.dart';
import 'CryptoService.dart';

class StorageService {
  // ----------------------------------------------------------------------- //
  static StorageService _instance;
  static StorageService get instance => _instance ??= StorageService();
  // ----------------------------------------------------------------------- //

  Future<User> checkPassword(String password) async {
    if (password == null || password.isEmpty) {
      throw Exception('Password should not be empty');
    }
    final preference = await SharedPreferences.getInstance();
    final hash = CryptoService.instance.getSecureHash(password);
    final data = preference.getString(hash);
    final jsonMap = json.decode(data);
    return User.fromJson(jsonMap);
  }

  Future<String> getWorkDir(String key) async {
    String storage;
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      storage = dir.absolute.path;
    } else {
      final dir = await getExternalStorageDirectory();
      storage = dir.absolute.path;
    }
    return storage;
  }
}
