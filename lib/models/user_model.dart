class AppUser {
  final String uid;
  final String email;
  final String name;
  final List<String> roles;
  final String currentRole;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.roles,
    required this.currentRole,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      roles: List<String>.from(map['roles'] as List? ?? []),
      currentRole: map['currentRole'] as String? ?? 'tenant',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'roles': roles,
      'currentRole': currentRole,
    };
  }

  /// Display-friendly label for any role key.
  static String roleLabel(String role) {
    switch (role) {
      case 'landlord':
        return 'Landlord';
      case 'property_manager':
        return 'Property Manager';
      default:
        return 'Tenant';
    }
  }

  AppUser copyWith({String? currentRole}) {
    return AppUser(
      uid: uid,
      email: email,
      name: name,
      roles: roles,
      currentRole: currentRole ?? this.currentRole,
    );
  }
}
