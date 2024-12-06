class User {
  final String id;
  final String email;
  final String password;
  final String role;
  final String userName;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    required this.userName,
  });

  factory User.fromMap(Map<String, dynamic> data) {
    return User(
      id: data['id'],
      email: data['email'],
      password: data['password'],
      role: data['role'],
      userName: data['user_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'role': role,
      'user_name': userName,
    };
  }
}