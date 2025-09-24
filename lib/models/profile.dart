class Profile {
  final int id;
  final String username;
  final String profileUrl;

  Profile({
    required this.id,
    required this.username,
    required this.profileUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      username: json['username'] ?? '',
      profileUrl: json['profile_url'] ?? '',
    );
  }
}
