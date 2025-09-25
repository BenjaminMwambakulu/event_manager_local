class Profile {
  final String id;
  final String username;
  final String profileUrl;
  final String? email;

  Profile({
    this.email="",
    required this.id,
    required this.username,
    required this.profileUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      email: json['email'] ?? '',
      id: json['id'].toString(),
      username: json['username'] ?? '',
      profileUrl: json['profile_url'] ?? '',
    );
  }
}