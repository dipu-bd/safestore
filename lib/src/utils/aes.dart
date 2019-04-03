/**
 * Source: https://github.com/leocavalcante/encrypt/blob/master/lib/src/algorithms/aes.dart
 */
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'package:pointycastle/api.dart';
import 'encrypted.dart';

export 'encrypted.dart';

class AESEncrypter {
  final IV iv;
  final Key key;
  final AESMode mode;
  final PaddedBlockCipher _cipher;
  final PaddedBlockCipherParameters _params;

  AESEncrypter(this.key, this.iv, {this.mode = AESMode.sic})
      : _cipher = PaddedBlockCipher('AES/${_modes[mode]}/PKCS7'),
        _params = PaddedBlockCipherParameters(
          mode == AESMode.ecb
              ? KeyParameter(key.bytes)
              : ParametersWithIV<KeyParameter>(
                  KeyParameter(key.bytes), iv.bytes),
          null,
        );

  Encrypted rawEncrypt(Uint8List bytes) {
    _cipher
      ..reset()
      ..init(true, _params);

    return Encrypted(_cipher.process(bytes));
  }

  Uint8List rawDecrypt(Encrypted encrypted) {
    _cipher
      ..reset()
      ..init(false, _params);

    return _cipher.process(encrypted.bytes);
  }

  /// Calls [encrypt] on the wrapped Algorithm.
  Encrypted encrypt(String input) {
    return rawEncrypt(
      Uint8List.fromList(
        convert.utf8.encode(input),
      ),
    );
  }

  /// Calls [decrypt] on the wrapped Algorithm.
  String decrypt(Encrypted encrypted) {
    return convert.utf8.decode(
      rawDecrypt(encrypted),
      allowMalformed: true,
    );
  }

  /// Sugar for `decrypt(Encrypted.fromBase16(encoded))`.
  String decrypt16(String encoded) {
    return decrypt(Encrypted.fromBase16(encoded));
  }

  /// Sugar for `decrypt(Encrypted.fromBase64(encoded))`.
  String decrypt64(String encoded) {
    return decrypt(Encrypted.fromBase64(encoded));
  }
}

enum AESMode {
  cbc,
  cfb64,
  ctr,
  ecb,
  ofb64Gctr,
  ofb64,
  sic,
}

const Map<AESMode, String> _modes = {
  AESMode.cbc: 'CBC',
  AESMode.cfb64: 'CFB-64',
  AESMode.ctr: 'CTR',
  AESMode.ecb: 'ECB',
  AESMode.ofb64Gctr: 'OFB-64/GCTR',
  AESMode.ofb64: 'OFB-64',
  AESMode.sic: 'SIC',
};
