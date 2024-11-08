class CheckIn {
  String session_id; // UUID for session ID
  String guest_id; // UUID for guest ID
  final String? souvenir;
  final String? angpau_label;
  final int? angpau;
  int pax_checked;
  String? meals;
  final String? note;
  final String delivery;
  final int guestNo;
  final String rsvp;
  final String status;
  final String? created_at; // Timestamp for when the check-in was created
  final String? updated_at; // Timestamp for when the check-in was last updated
  final bool synced; // Whether the check-in is synced with the server

  CheckIn({
    required this.session_id,
    required this.guest_id,
    this.souvenir = '',
    this.angpau_label = '',
    this.angpau = 0,
    this.pax_checked = 1,
    this.meals = '',
    this.note = '',
    this.delivery = 'no',
    this.guestNo = 1,
    this.rsvp = 'pending',
    this.status = 'not check-in yet',
    this.created_at,
    this.updated_at,
    this.synced = false,
  });

  // Factory method to create a CheckIn instance from a map (e.g., from database query)
  factory CheckIn.fromMap(Map<String, dynamic> map) => CheckIn(
        session_id: map['session_id'] as String,
        guest_id: map['guest_id'] as String,
        souvenir: map['souvenir'] as String? ?? '',
        angpau_label: map['angpau_label'] as String? ?? '',
        angpau: map['angpau'] as int? ?? 0,
        pax_checked: map['pax_checked'] as int? ?? 1,
        meals: map['meals'] as String? ?? '',
        note: map['note'] as String? ?? '',
        delivery: map['delivery'] as String? ?? 'no',
        guestNo: map['guestNo'] as int? ?? 1,
        rsvp: map['rsvp'] as String,
        status: map['status'] as String? ?? 'not check-in yet',
        created_at: map['created_at'] as String?,
        updated_at: map['updated_at'] as String?,
        synced: (map['synced'] as int?) == 1,
      );

  // Method to convert a CheckIn instance to a map (e.g., for saving to a database)
  Map<String, dynamic> toMap() => {
        'session_id': session_id,
        'guest_id': guest_id,
        'souvenir': souvenir,
        'angpau_label': angpau_label,
        'angpau': angpau,
        'pax_checked': pax_checked,
        'meals': meals,
        'note': note,
        'delivery': delivery,
        'guestNo': guestNo,
        'rsvp': rsvp,
        'status': status,
        'created_at': created_at,
        'updated_at': updated_at,
        'synced': synced ? 1 : 0,
      };

// Factory method to create a CheckIn instance from a JSON object
  factory CheckIn.fromJson(Map<String, dynamic> json) {
    return CheckIn(
      session_id: json['session_id'] as String,
      guest_id: json['guest_id'] as String,
      souvenir: json['souvenir'] as String? ?? '',
      angpau_label: json['angpau_label'] as String? ?? '',
      angpau: json['angpau'] is int
          ? json['angpau']
          : int.tryParse(json['angpau'].toString()) ?? 0,
      pax_checked: json['pax_checked'] is int
          ? json['pax_checked']
          : int.tryParse(json['pax_checked'].toString()) ?? 0,
      meals: json['meals'] as String? ?? '',
      note: json['note'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'no',
      guestNo: json['guestNo'] is int
          ? json['guestNo']
          : int.tryParse(json['guestNo'].toString()) ?? 0,
      rsvp: json['rsvp']
          .toString(), // Konversi ke String untuk menangani kasus int atau String
      status: json['status'] as String? ?? 'not check-in yet',
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  // Method to convert a CheckIn instance to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'session_id': session_id,
      'guest_id': guest_id,
      'souvenir': souvenir,
      'angpau_label': angpau_label,
      'angpau': angpau,
      'pax_checked': pax_checked,
      'meals': meals,
      'note': note,
      'delivery': delivery,
      'guestNo': guestNo,
      'rsvp': rsvp,
      'status': status,
      'created_at': created_at,
      'updated_at': updated_at,
      'synced': synced,
    };
  }

  // Factory method for creating an empty CheckIn instance
  factory CheckIn.empty() {
    return CheckIn(
      session_id: '',
      guest_id: '',
      souvenir: '',
      angpau_label: '',
      angpau: 0,
      pax_checked: 1,
      meals: '',
      note: '',
      delivery: 'no',
      guestNo: 1,
      rsvp: 'pending',
      status: 'not check-in yet',
      created_at: null,
      updated_at: null,
      synced: false,
    );
  }

  CheckIn copyWith({
    String? session_id,
    String? guest_id,
    String? souvenir,
    String? angpau_label,
    int? angpau,
    int? pax_checked,
    String? meals,
    String? note,
    String? delivery,
    int? guestNo,
    String? rsvp,
    String? status,
    String? created_at,
    String? updated_at,
    bool? synced,
  }) {
    return CheckIn(
      session_id: session_id ?? this.session_id,
      guest_id: guest_id ?? this.guest_id,
      souvenir: souvenir ?? this.souvenir,
      angpau_label: angpau_label ?? this.angpau_label,
      angpau: angpau ?? this.angpau,
      pax_checked: pax_checked ?? this.pax_checked,
      meals: meals ?? this.meals,
      note: note ?? this.note,
      delivery: delivery ?? this.delivery,
      guestNo: guestNo ?? this.guestNo,
      rsvp: rsvp ?? this.rsvp,
      status: status ?? this.status,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
      synced: synced ?? this.synced,
    );
  }
}
