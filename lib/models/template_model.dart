class Template {
  final String? template_id;
  final String client_id;
  final String? greeting;
  final String? opening;
  final String? link;
  final String? closing;
  final String? key;
  final String? created_at;
  final String? updated_at;
  final bool synced;

  Template({
    this.template_id,
    required this.client_id,
    this.greeting,
    this.opening,
    this.link,
    this.closing,
    this.key,
    this.created_at,
    this.updated_at,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'template_id': template_id,
      'client_id': client_id,
      'greeting': greeting,
      'opening': opening,
      'link': link,
      'closing': closing,
      'key': key,
      'created_at': created_at,
      'updated_at': updated_at,
      'synced': synced ? 1 : 0,
    };
  }

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      template_id: map['template_id'] as String?,
      client_id: map['client_id'] as String,
      greeting: map['greeting'] as String?,
      opening: map['opening'] as String?,
      link: map['link'] as String?,
      closing: map['closing'] as String?,
      key: map['key'] as String?,
      created_at: map['created_at'] as String?,
      updated_at: map['updated_at'] as String?,
      synced: (map['synced'] as int) == 1,
    );
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      template_id: json['template_id'] as String?,
      client_id: json['client_id'] as String,
      greeting: json['greeting'] as String?,
      opening: json['opening'] as String?,
      link: json['link'] as String?,
      closing: json['closing'] as String?,
      key: json['key'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      synced: json['synced'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'template_id': template_id,
      'client_id': client_id,
      'greeting': greeting,
      'opening': opening,
      'link': link,
      'closing': closing,
      'key': key,
      'created_at': created_at,
      'updated_at': updated_at,
      'synced': synced,
    };
  }
}
