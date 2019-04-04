import 'package:uuid/uuid.dart';
import 'package:safestore/src/utils/aes.dart';

class User {
  final String id;
  final String workdir;
  final String password;

  User(this.password, this.workdir) : id = Uuid().v4();

  User.fromJson(Map<String, dynamic> data, this.password)
      : id = data['id'] ?? Uuid().v4(),
        workdir = data['workdir'];

  Map<String, dynamic> toJson() {
    final data = Map<String, dynamic>();
    data['id'] = id ?? Uuid().v4();
    data['workdir'] = workdir;
    return data;
  }

  // ----------------------------------------------------------------------- //

  AESEncrypter _encrypter;
  AESEncrypter get encrypter => _encrypter ??= AESEncrypter(
        Key.fromUtf8(password),
        IV.fromUtf8(id),
      );
}
