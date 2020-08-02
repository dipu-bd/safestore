import 'package:archive/archive.dart';

class Compression {
  static List<int> compress(Iterable<int> data) {
    return GZipEncoder().encode(data);
  }

  static List<int> uncompress(Iterable<int> data) {
    return GZipDecoder().decodeBytes(data);
  }
}
