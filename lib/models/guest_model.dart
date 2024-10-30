class Guest {
  final String? guest_id; // UUID for guest ID
  final String? guest_qr;
  final String client_id; // UUID for client ID
  final String name;
  final String? email;
  final String? phone;
  final int pax;
  final String tables; // Changed to non-nullable String
  final String cat;
  final String? created_at; // Timestamp for when the guest was last updated
  final String? updated_at; // Timestamp for when the guest was last updated
  final bool synced; // Whether the guest is synced with the server

  Guest({
    this.guest_id,
    this.guest_qr,
    required this.client_id,
    required this.name,
    this.email,
    this.phone,
    this.pax = 1,
    this.tables = '', // Default to an empty string
    this.cat = 'REGULAR',
    this.created_at,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create a Guest instance from a map (e.g., from database query)
  factory Guest.fromMap(Map<String, dynamic> map) => Guest(
        guest_id: map['guest_id'] as String?,
        guest_qr: map['guest_qr'] as String?,
        name: map['name'] as String,
        email: map['email'] as String?,
        client_id: map['client_id'] as String,
        phone: map['phone'] as String?,
        pax: map['pax'] as int,
        tables:
            map['tables'] as String? ?? '', // Default to empty string if null
        cat: map['cat'] as String,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int) == 1,
      );

  // Method to convert a Guest instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'guest_id': guest_id,
        'guest_qr': guest_qr,
        'name': name,
        'email': email,
        'client_id': client_id,
        'phone': phone,
        'pax': pax,
        'tables': tables,
        'cat': cat,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

  // Factory method to create a Guest instance from a JSON object
  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      guest_id: json['guest_id'] as String?,
      guest_qr: json['guest_qr'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      client_id: json['client_id'] as String,
      phone: json['phone'] as String?,
      pax: int.parse(json['pax'].toString()),
      tables:
          json['tables'] as String? ?? '', // Default to empty string if null
      cat: json['cat'] as String,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  // Method to convert a Guest instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'guest_id': guest_id,
      'guest_qr': guest_qr,
      'name': name,
      'email': email,
      'client_id': client_id,
      'phone': phone,
      'pax': pax,
      'tables': tables,
      'cat': cat,
      'updated_at': updated_at,
      'synced': synced,
    };
  }

  // Factory method for creating an empty Guest instance
  factory Guest.empty() {
    return Guest(
      guest_id: null,
      guest_qr: null,
      name: '',
      email: null,
      client_id: '',
      phone: null,
      pax: 0,
      tables: '', // Default to empty string
      cat: 'REGULAR',
      updated_at: null,
      synced: false,
    );
  }

  Guest copyWith({
    String? guest_id,
    String? guest_qr,
    String? name,
    String? email,
    String? client_id,
    String? phone,
    int? pax,
    String? tables,
    String? cat,
    String? updated_at,
    bool? synced,
  }) {
    return Guest(
      guest_id: guest_id ?? this.guest_id,
      guest_qr: guest_qr ?? this.guest_qr,
      name: name ?? this.name,
      email: email ?? this.email,
      client_id: client_id ?? this.client_id,
      phone: phone ?? this.phone,
      pax: pax ?? this.pax,
      tables: tables ?? this.tables,
      cat: cat ?? this.cat,
      updated_at: updated_at ?? this.updated_at,
      synced: synced ?? this.synced,
    );
  }
}
