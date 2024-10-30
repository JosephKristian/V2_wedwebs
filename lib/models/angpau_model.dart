class AngpauModel {
  // UUID for table ID
  final String session_id; // UUID for session ID
  final String key;
  final int counter;
  final String? updated_at; // Timestamp for when the table was last updated
  final bool synced; // Whether the table is synced with the server

  AngpauModel({
    required this.session_id,
    required this.key,
    required this.counter,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create a AngpauModel instance from a map (e.g., from database query)
  factory AngpauModel.fromMap(Map<String, dynamic> map) => AngpauModel(
        session_id: map['session_id'] as String,
        key: map['key'] as String,
        counter: map['counter'] as int,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int) == 1,
      );

  // Method to convert a AngpauModel instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'session_id': session_id,
        'key': key,
        'counter': counter,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

  // Factory method to create a AngpauModel instance from a JSON object
  factory AngpauModel.fromJson(Map<String, dynamic> json) {
    return AngpauModel(
      session_id: json['session_id'] as String,
      key: json['key'] as String,
      counter:
          json['counter'] is int ? json['counter'] : int.parse(json['counter']),
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  // Method to convert a AngpauModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'session_id': session_id,
      'key': key,
      'counter': counter,
      'updated_at': updated_at,
      'synced': synced,
    };
  }

  // Factory method for creating an empty AngpauModel instance
  factory AngpauModel.empty() {
    return AngpauModel(
      session_id: '',
      key: 'none',
      counter: 0,
      updated_at: null,
      synced: false,
    );
  }
}
