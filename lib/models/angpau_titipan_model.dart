class AngpauTitipanModel {
  // Primary key for the Angpau_titipan table
  final String angpau_titipan_id; // ID for the Angpau titipan
  final String session_id; // UUID for session ID
  final String guest_id; // ID for guest
  final String? angpau_titipan_name; // Name for the Angpau titipan
  final String? counter_label; // Name for the Angpau titipan
  final String amount; // Amount for the Angpau titipan
  final bool synced; // Whether the table is synced with the server
  final String? created_at; // Timestamp for when the entry was created
  final String? updated_at; // Timestamp for when the entry was last updated

  AngpauTitipanModel({
    required this.angpau_titipan_id,
    required this.session_id,
    required this.guest_id,
    this.angpau_titipan_name,
    this.counter_label,
    this.amount = '0',
    this.synced = false,
    this.created_at,
    this.updated_at,
  });

  // Factory method to create an AngpauTitipanModel instance from a map
  factory AngpauTitipanModel.fromMap(Map<String, dynamic> map) {
    return AngpauTitipanModel(
      angpau_titipan_id: map['angpau_titipan_id'] as String? ?? '',
      session_id: map['session_id'] as String? ?? '',
      guest_id:
          map['guest_id'] as String? ?? '', // Pastikan ini juga menangani null
      angpau_titipan_name: map['angpau_titipan_name'] as String? ?? '',
      counter_label: map['counter_label'] as String? ?? '',
      amount: map['amount']?.toString() ??
          '0', // Ubah ke String dan berikan nilai default
      synced: (map['synced'] as int?) == 1, // Pastikan ini juga menangani null
      created_at: map['created_at'] as String? ?? '',
      updated_at: map['updated_at'] as String? ?? '',
    );
  }

  // Method to convert an AngpauTitipanModel instance to a map
  Map<String, dynamic> toMap() {
    return {
      'angpau_titipan_id': angpau_titipan_id,
      'session_id': session_id,
      'guest_id': guest_id,
      'angpau_titipan_name': angpau_titipan_name,
      'counter_label': counter_label,
      'amount': amount,
      'synced': synced ? 1 : 0,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  // Factory method to create an AngpauTitipanModel instance from a JSON object
  factory AngpauTitipanModel.fromJson(Map<String, dynamic> json) {
    return AngpauTitipanModel(
      angpau_titipan_id: json['angpau_titipan_id'] as String,
      session_id: json['session_id'] as String,
      guest_id: json['guest_id'] as String,
      angpau_titipan_name: json['angpau_titipan_name'] as String?,
      counter_label: json['counter_label'] as String?,
      amount: json['amount'] as String,
      synced: json['synced'] ?? false,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
    );
  }

  // Method to convert an AngpauTitipanModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'angpau_titipan_id': angpau_titipan_id,
      'session_id': session_id,
      'guest_id': guest_id,
      'angpau_titipan_name': angpau_titipan_name,
      'counter_label': counter_label,
      'amount': amount,
      'synced': synced,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  // Factory method for creating an empty AngpauTitipanModel instance
  factory AngpauTitipanModel.empty() {
    return AngpauTitipanModel(
      angpau_titipan_id: '',
      session_id: '',
      guest_id: '',
      angpau_titipan_name: null,
      counter_label: null,
      amount: '0',
      synced: false,
      created_at: null,
      updated_at: null,
    );
  }
}
