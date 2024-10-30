class Client {
  final String? client_id;
  final String name;
  final String email;
  final String? phone;
  final String? created_at;
  final String? updated_at;
  final bool synced;

  Client({
    this.client_id,
    required this.name,
    required this.email,
    this.phone,
    this.created_at,
    this.updated_at,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'client_id': client_id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': created_at,
      'updated_at': updated_at,
      'synced': synced ? 1 : 0,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      client_id: map['client_id'] as String?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      created_at: map['created_at'] as String?,
      updated_at: map['updated_at'] as String?,
      synced: (map['synced'] as int) == 1,
    );
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      client_id: json['client_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': client_id,
      'name': name,
      'email': email,
      'phone': phone,
      'created_at': created_at,
      'updated_at': updated_at,
      'synced': synced,
    };
  }
}
