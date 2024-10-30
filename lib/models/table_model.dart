class TableModel {
  final String? table_id; // UUID for table ID
  final String session_id; // UUID for session ID
  final String table_name;
  final int seat;
  final String? updated_at; // Timestamp for when the table was last updated
  final bool synced; // Whether the table is synced with the server

  TableModel({
    this.table_id,
    required this.session_id,
    required this.table_name,
    required this.seat,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create a TableModel instance from a map (e.g., from database query)
  factory TableModel.fromMap(Map<String, dynamic> map) => TableModel(
        table_id: map['table_id'] as String?,
        session_id: map['session_id'] as String,
        table_name: map['table_name'] as String,
        seat: map['seat'] as int,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int) == 1,
      );

  // Method to convert a TableModel instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'table_id': table_id,
        'session_id': session_id,
        'table_name': table_name,
        'seat': seat,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

  // Factory method to create a TableModel instance from a JSON object
  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      table_id: json['table_id'] as String?,
      session_id: json['session_id'] as String,
      table_name: json['table_name'] as String,
      seat: json['seat'] is int ? json['seat'] : int.parse(json['seat']),
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  // Method to convert a TableModel instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'table_id': table_id,
      'session_id': session_id,
      'table_name': table_name,
      'seat': seat,
      'updated_at': updated_at,
      'synced': synced,
    };
  }

  // Factory method for creating an empty TableModel instance
  factory TableModel.empty() {
    return TableModel(
      table_id: null,
      session_id: '',
      table_name: 'none',
      seat: 0,
      updated_at: null,
      synced: false,
    );
  }
}
