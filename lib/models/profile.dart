class Profile {
  final String id;
  final String? userId;
  final String username;
  final String profileUrl;
  final String email;
  final String? phone;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.userId,
    required this.username,
    required this.profileUrl,
    this.email = "",
    this.phone,
    this.role = "customer",
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      username: json['username'] ?? '',
      profileUrl: json['profile_url'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'customer',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'profile_url': profileUrl,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}
