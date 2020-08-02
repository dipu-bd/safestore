import 'package:safestore/src/models/serializable.dart';

class Note extends Serializable {
  String title;
  String body;

  @override
  void fromJson(Map<String, dynamic> data) {
    super.fromJson(data);
    title = data['title'];
    body = data['body'];
  }

  @override
  Map<String, dynamic> toJson() {
    final data = super.toJson();
    data['title'] = title;
    data['body'] = body;
    return data;
  }
}
