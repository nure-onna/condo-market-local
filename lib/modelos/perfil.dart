class Profile {
  final String id;
  final String email;
  final String username;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.email,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.aPartirDeJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    email: json['email'] as String,
    username: json['username'] as String,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> converterParaJson() => {
    'id': id,
    'email': email,
    'username': username,
    'avatar_url': avatarUrl,
    'created_at': createdAt.toIso8601String(),
  };
}
