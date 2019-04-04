import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:safestore/src/utils/aes.dart';

final String defaultIV = '1234567890123456';
final String appendPass = '@#\$%^1233&*&%\$@#%^&*54';

class CryptoService {
  // ----------------------------------------------------------------------- //
  static CryptoService _instance;
  static CryptoService get instance => _instance ??= CryptoService();
  // ----------------------------------------------------------------------- //

  /// Generates a hash and return the base64 representation
  String getSecureHash(String str) {
    final digest = Digest('SHA-256');
    str = (str + appendPass).substring(0, 24);
    final data = Uint8List.fromList(utf8.encode(str));
    final out = digest.process(data);
    return base64.encode(out.toList());
  }

  /// Returns a Base64 encrypted message
  String encryptString(String password, String text, {String ivParam}) {
    password = (password + appendPass).substring(0, 24);
    final key = Key.fromUtf8(password);
    final iv = IV.fromUtf8(ivParam ?? defaultIV);
    final encryptor = AESEncrypter(key, iv);
    return encryptor.encrypt(text ?? '').base64;
  }

  /// Returns the original plain text message
  String decryptString(String password, String base64, {String ivParam}) {
    password = (password + appendPass).substring(0, 24);
    final key = Key.fromUtf8(password);
    final iv = IV.fromUtf8(ivParam ?? defaultIV);
    final encryptor = AESEncrypter(key, iv);
    return encryptor.decrypt64(base64);
  }
}
