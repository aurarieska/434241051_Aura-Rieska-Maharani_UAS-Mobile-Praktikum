class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String role;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.photoUrl,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'full_name': fullName,
    'role': role,
    'phone': phone,
    'photo_url': photoUrl,
    'created_at': createdAt.toIso8601String(),
  };

  UserModel copyWith({
    String? username,
    String? email,
    String? fullName,
    String? role,
    String? phone,
    String? photoUrl,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}