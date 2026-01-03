// User role enum
enum UserRole {
  user,
  admin;

  String toJson() => name;
  
  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value,
      orElse: () => UserRole.user,
    );
  }
}

class Profile {
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final DateTime? dateOfBirth;
  final UserRole role;

  Profile({
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.dateOfBirth,
    this.role = UserRole.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'role': role.toJson(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      role: json['role'] != null 
          ? UserRole.fromJson(json['role'])
          : UserRole.user,
    );
  }

  Profile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    DateTime? dateOfBirth,
    UserRole? role,
  }) {
    return Profile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      role: role ?? this.role,
    );
  }
  
  bool get isAdmin => role == UserRole.admin;
}
