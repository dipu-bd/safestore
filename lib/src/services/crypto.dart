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

  static String hashPassword(String password) {
    if (![128, 192, 256].contains(CryptoConfig.AES_BITS)) {
      throw ArgumentError.value(
          CryptoConfig.AES_BITS, 'CryptoConfig.AES_BITS', 'Invalid for AES');
    }

    final params = Pbkdf2Parameters(
      Uint8List.fromList(utf8.encode(CryptoConfig.PBKDF2_SALT)),
      CryptoConfig.PBKDF2_ITERATIONS,
      CryptoConfig.AES_BITS,
    );

    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    );
    derivator.init(params);

    final hashBytes = derivator.process(
      Uint8List.fromList(utf8.encode(password)),
    );
    return base64.encode(hashBytes.toList());
  }

  // ---------------------------------------------------------------------------

  static String makeHash(String text) {
    final digest = SHA256Digest();
    final data = utf8.encode(text);
    final hash = digest.process(data);
    return base64.encode(hash.toList());
  }

  // ---------------------------------------------------------------------------

  static Uint8List _AES(
      bool encrypt, Uint8List data, Uint8List iv, Uint8List key) {
    if (iv.length * 8 != 128) {
      throw ArgumentError.value(iv, 'iv', 'Invalid iv length for AES');
    }
    if (![128, 192, 256].contains(key.length * 8)) {
      throw ArgumentError.value(key, 'key', 'Invalid key length for AES');
    }

    final cbc = CBCBlockCipher(AESFastEngine());
    cbc.init(encrypt, ParametersWithIV(KeyParameter(key), iv));

    final source = pad(data, 128); // padded plain text
    final dest = Uint8List(source.length); // allocate space

    var offset = 0;
    while (offset < source.length) {
      offset += cbc.processBlock(source, offset, dest, offset);
    }
    assert(offset == source.length);

    return dest;
  }

  static Uint8List encrypt(Uint8List plain, String passwordHash) {
    // Get 256 bit long key
    final key = base64.decode(passwordHash);
    // Generate 128-bit long iv
    final iv = generateRandom(128);
    // Pad plain text
    plain = pad(plain, 128);
    // Encrypt using AES/CBC
    final cipher = _AES(true, plain, iv, key); // true=encrypt
    // Put iv at specific position
    final pos = key[128] % cipher.length;
    cipher.insertAll(pos, iv);
    // all done
    return cipher;
  }

  static Uint8List decrypt(Uint8List cipher, String passwordHash) {
    // Get 256 bit long key
    final key = base64.decode(passwordHash);
    // Extract iv from specific position of the cipher
    final pos = key[128] % cipher.length;
    final iv = cipher.sublist(pos, pos + 128);
    cipher.removeRange(pos, pos + 128);
    // Decrypt using AES/CBC
    final plain = _AES(false, cipher, iv, key); // false=decrypt
    // Unpad and return
    return unpad(plain);
  }
}
