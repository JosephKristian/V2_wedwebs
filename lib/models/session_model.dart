class Session {
  final String? session_id; // UUID for session ID
  final String event_id; // UUID for event ID
  final String session_name;
  final String time;
  final String location;
  final String? updated_at; // Timestamp for when the session was last updated
  final bool synced; // Whether the session is synced with the server

  Session({
    this.session_id,
    required this.event_id,
    required this.session_name,
    required this.time,
    required this.location,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create a Session instance from a map (e.g., from JSON)
  factory Session.fromMap(Map<String, dynamic> map) => Session(
        session_id: map['session_id'] as String?,
        event_id: map['event_id'] as String,
        session_name: map['session_name'] as String,
        time: map['time'] as String,
        location: map['location'] as String,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int) == 1,
      );

  // Method to convert a Session instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'session_id': session_id,
        'event_id': event_id,
        'session_name': session_name,
        'time': time,
        'location': location,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

  // Factory method to create a Session instance from a JSON object
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      session_id: json['session_id'] as String?,
      event_id: json['event_id'] as String,
      session_name: json['session_name'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  // Method to convert a Session instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'session_id': session_id,
      'event_id': event_id,
      'session_name': session_name,
      'time': time,
      'location': location,
      'updated_at': updated_at,
      'synced': synced,
    };
  }
}
