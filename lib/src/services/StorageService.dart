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
    final hash = CryptoService.instance.getSecureHash(password);
    String workdir = await getWorkDir(hash);
    final user = User(password, workdir);
    final jsonStr = json.encode(user.toJson());
    final base64 = CryptoService.instance.encryptString(password, jsonStr);
    final preference = await SharedPreferences.getInstance();
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
    key = key.substring(16) + key.substring(0, 16);
    key = key.replaceAll('/', '.');
    key = key.replaceAll('=', '_');
    storage += '/SafeStore/$key';
    return storage;
  }

  List<String> fileList(User user) {
    try {
      final meta = File(user.workdir + '/r');
      final data = meta.readAsBytesSync();
      final encrypted = Encrypted.fromList(data);
      final jsonStr = user.encrypter.decrypt(encrypted);
      return json.decode(jsonStr);
    } catch (err) {
      print('<!> fileList: $err');
      return [];
    }
  }

  void saveFileList(User user, List<String> files) {
    try {
      final jsonStr = json.encode(files);
      final data = user.encrypter.encrypt(jsonStr).bytes.toList();
      final meta = File(user.workdir + '/r');
      meta.createSync(recursive: true);
      meta.writeAsBytesSync(data);
    } catch (err) {
      print('<!> saveFileList: ${files.length}');
      throw Exception('Failed to save file list');
    }
  }
}
