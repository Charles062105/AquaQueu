class AppUser {
  const AppUser({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.uid = '',
    this.role = 'customer',
  });

  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String role;

  AppUser copyWith({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? address,
    String? uid,
    String? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      role: role ?? this.role,
    );
  }

  static const demo = AppUser(
    fullName: 'Alex Santos',
    email: 'alex.santos@email.com',
    phoneNumber: '+63 917 123 4567',
    address: '24 Sampaguita Street, Quezon City',
  );
}
