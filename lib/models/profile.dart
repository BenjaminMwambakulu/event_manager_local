class Profile {
  final String id;
  final String username;
  final String profileUrl;

  Profile({
    required this.id,
    required this.username,
    required this.profileUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      profileUrl: json['profile_url'] ?? '',
    );
  }
}