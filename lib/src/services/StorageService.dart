import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safestore/src/models/user.dart';
import 'package:safestore/src/utils/encrypted.dart';
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
    final jsonStr = CryptoService.instance.decryptString(password, data);
    final jsonMap = json.decode(jsonStr);
    return User.fromJson(jsonMap, password);
  }

  Future<User> createNewUser(String password) async {
    if (password == null || password.isEmpty) {
      throw Exception('Password should not be empty');
    }
    final user = User(password);
    final jsonStr = json.encode(user.toJson());
    final base64 = CryptoService.instance.encryptString(password, jsonStr);
    final preference = await SharedPreferences.getInstance();
    final hash = CryptoService.instance.getSecureHash(password);
    final success = await preference.setString(hash, base64);
    if (!success) throw Exception('Failed to update preference');
    return user;
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
