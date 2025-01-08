class AuthModel {
  final String email;
  final String password;
  final String? name;

  AuthModel({
    required this.email,
    required this.password,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    };
  }
}
