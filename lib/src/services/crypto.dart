import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import "package:pointycastle/pointycastle.dart";
import 'package:safestore/src/config/crypto.dart';

abstract class Crypto {
  static FortunaRandom _secureRandom;

  static Uint8List generateRandom(int bitLength) {
    if (_secureRandom == null) {
      _secureRandom = FortunaRandom();
      final seeder = Random.secure();
      final seeds = List.generate(32, (index) => seeder.nextInt(256));
      _secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    }
    return _secureRandom.nextBytes(bitLength ~/ 8);
  }

  static Uint8List pad(Uint8List bytes, int blockSize) {
    final padLength = blockSize - (bytes.length % blockSize);
    final padded = Uint8List(bytes.length + padLength)..setAll(0, bytes);
    PKCS7Padding().addPadding(padded, bytes.length);
    return padded;
  }

  static Uint8List unpad(Uint8List padded) {
    final padLength = PKCS7Padding().padCount(padded);
    return padded.sublist(0, padded.length - padLength);
  }

  // ---------------------------------------------------------------------------

  static Uint8List hashPassword(String password) {
    if (![128, 192, 256].contains(CryptoConfig.AES_BITS)) {
      throw ArgumentError.value(
          CryptoConfig.AES_BITS, 'CryptoConfig.AES_BITS', 'Invalid for AES');
    }

    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );

    final params = Pbkdf2Parameters(
      Uint8List.fromList(utf8.encode(CryptoConfig.PBKDF2_SALT)),
      CryptoConfig.PBKDF2_ITERATIONS,
      CryptoConfig.AES_BITS ~/ 8,
    );

    derivator.init(params);

    final hashBytes = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );
    assert(hashBytes.length * 8 == CryptoConfig.AES_BITS);

    return hashBytes;
  }

  static Uint8List makeHash(Uint8List data, [int iteration = 1]) {
    final digest = SHA256Digest();
    for (int i = 0; i < iteration; ++i) {
      data = digest.process(data);
    }
    return data;
  }

  static String generateId() {
    final clock = DateTime.now().microsecondsSinceEpoch;
    final random = generateRandom(128);
    random.buffer.asByteData().setUint64(0, clock);
    return base64.encode(random);
  }

  // ---------------------------------------------------------------------------

  static Uint8List _AES(
      bool encrypt, Uint8List source, Uint8List iv, Uint8List key) {
    if (iv.length * 8 != 128) {
      throw ArgumentError.value(iv, 'iv', 'Invalid iv length for AES');
    }
    if (![128, 192, 256].contains(key.length * 8)) {
      throw ArgumentError.value(key, 'key', 'Invalid key length for AES');
    }

    final cbc = CBCBlockCipher(AESFastEngine());
    cbc.init(encrypt, ParametersWithIV(KeyParameter(key), iv));

    final dest = Uint8List(source.length); // allocate space

    var offset = 0;
    while (offset < source.length) {
      offset += cbc.processBlock(source, offset, dest, offset);
    }
    assert(offset == source.length);

    return dest;
  }

  static Uint8List encrypt(Iterable<int> input, Uint8List key) {
    Uint8List plain = Uint8List.fromList(input);
    // Generate 128-bit long iv
    final iv = generateRandom(128);
    // Pad plain text
    plain = pad(plain, 128);
    // Encrypt using AES/CBC
    final cipher = _AES(true, plain, iv, key); // true=encrypt
    // Put iv at specific position
    final output = <int>[]..addAll(iv)..addAll(cipher);
    // all done
    return Uint8List.fromList(output);
  }

  static Uint8List decrypt(Iterable<int> input, Uint8List key) {
    // Extract iv from specific position of the cipher
    final iv = Uint8List.fromList(input.take(16).toList());
    final cipher = Uint8List.fromList(input.skip(16).toList());
    // Decrypt using AES/CBC
    final plain = _AES(false, cipher, iv, key); // false=decrypt
    // Unpad the plain text
    final output = unpad(plain);
    // all done
    return output;
  }

  static String encryptText(String text, Uint8List key) {
    final cipher = encrypt(utf8.encode(text), key);
    return utf8.decode(cipher.toList());
  }

  static String decryptText(String text, Uint8List key) {
    final plain = decrypt(utf8.encode(text), key);
    return utf8.decode(plain.toList());
  }
}
