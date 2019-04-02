enum UserType {
  Biometrics,
  Password,
}

class User {
  final UserType type;
  final String workdir;

  User.fromJson(Map<String, dynamic> data)
      : type = data['type'],
        workdir = data['workdir'];

  Map<String, dynamic> toJson() {
    final data = Map<String, dynamic>();
    data['type'] = type;
    data['workdir'] = workdir;
    return data;
  }
}
