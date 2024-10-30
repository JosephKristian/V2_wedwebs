import 'package:uuid/uuid.dart';

class Usher {
  final String usher_id; // UUID tidak boleh nullable
  final String? client_id; // client_id bisa nullable
  final String name;
  final String email;
  final String? password;
  final String role; // Default 'user'
  final String? createdAt; // Nullable
  final String? updatedAt; // Nullable
  final bool synced;

  Usher({
    required this.usher_id, // UUID harus selalu diisi
    this.client_id,
    required this.name,
    required this.email,
    this.password,
    this.role = 'user', // Default role
    this.createdAt,
    this.updatedAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'usher_id': usher_id,
      'client_id': client_id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  factory Usher.fromMap(Map<String, dynamic> map) {
    return Usher(
      usher_id: map['usher_id'] as String,
      client_id: map['client_id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      role: map['role'] as String? ?? 'user',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      synced: (map['synced'] as int) == 1,
    );
  }

  // Generate a new UUID for the usher_id
  static String generateUUID() {
    var uuid = Uuid();
    return uuid.v4(); // Generate a version 4 UUID
  }

  factory Usher.fromJson(Map<String, dynamic> json) {
    return Usher(
      usher_id: json['usher_id'] as String,
      client_id: json['client_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] as String? ?? 'user',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usher_id': usher_id,
      'client_id': client_id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'synced': synced,
    };
  }
}
