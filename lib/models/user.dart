enum UserRole { customer, admin }

class AppUser {
  final String id;
  final String email;
  final String password; // demo only
  final UserRole role;
  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
  });
}
