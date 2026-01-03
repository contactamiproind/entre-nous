class User {
  final String username;
  final String password;
  final bool isAdmin;
  int currentLevel;

  User({
    required this.username,
    required this.password,
    this.isAdmin = false,
    this.currentLevel = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'isAdmin': isAdmin,
      'currentLevel': currentLevel,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      password: json['password'],
      isAdmin: json['isAdmin'] ?? false,
      currentLevel: json['currentLevel'] ?? 1,
    );
  }
}
