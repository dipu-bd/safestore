import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  static final storage = FlutterSecureStorage();

  static final _credentialKey = 'google-credentials';
}
