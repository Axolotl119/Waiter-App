enum UserRole { waiter, admin }

class AppUser {
  final String id;      // Firebase UID
  final String email;
  final String password; // Chỉ dùng khi đăng ký hoặc đăng nhập
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.password,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String,
      role: (map['role'] as String) == 'admin' ? UserRole.admin : UserRole.waiter,
      password: map['password'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role == UserRole.admin ? 'admin' : 'waiter',
  };
}

