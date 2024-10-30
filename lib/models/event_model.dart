class Event {
  final String? event_id;
  final String? client_id;
  final String event_name;
  final String date;
  final String? updated_at;
  final bool synced;
  Event({
    required this.event_id,
    required this.client_id,
    required this.event_name,
    required this.date,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create an Event instance from a map (e.g., from JSON)
  factory Event.fromMap(Map<String, dynamic> map) => Event(
        event_id: map['event_id'] as String,
        client_id: map['client_id'] as String,
        event_name: map['event_name'] as String,
        date: map['date'] as String,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int) == 1,
      );

  // Method to convert an Event instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'event_id': event_id,
        'client_id': client_id,
        'event_name': event_name,
        'date': date,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      event_id: json['event_id'] as String?,
      client_id: json['client_id'] as String?,
      event_name: json['event_name'] as String,
      date: json['date'] as String,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': event_id,
      'client_id': client_id,
      'event_name': event_name,
      'date': date,
      'updated_at': updated_at,
      'synced': synced,
    };
  }
}
