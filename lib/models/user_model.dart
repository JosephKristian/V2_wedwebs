import 'package:uuid/uuid.dart';

class User {
  final String user_id; // UUID tidak boleh nullable
  final String role;
  final String password;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.user_id, // UUID harus selalu diisi
    required this.role,
    required this.password,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'password': password,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      user_id: map['user_id'] as String,
      role: map['role'],
      password: map['password'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Generate a new UUID for the user_id
  static String generateUUID() {
    var uuid = Uuid();
    return uuid.v4(); // Generate a version 4 UUID
  }
}
