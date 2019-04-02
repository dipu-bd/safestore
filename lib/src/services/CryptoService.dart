import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';

class CryptoService {
  // ----------------------------------------------------------------------- //
  static CryptoService _instance;
  static CryptoService get instance => _instance ??= CryptoService();
  // ----------------------------------------------------------------------- //

  String getSecureHash(String str) {
    Digest sha256 = Digest('SHA-256');
    str = str.padRight(16, '%').substring(0, 16);
    final bytes = Uint8List.fromList(utf8.encode(str));
    final hash = sha256.process(bytes);
    final cipher = base64.encode(hash);
    return cipher.substring(0, 16);
  }
}
