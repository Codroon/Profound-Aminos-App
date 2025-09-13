class TrackingUpdate {
  final String id;
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final Map<String, dynamic>? metadata;

  const TrackingUpdate({
    required this.id,
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.metadata,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zip_code'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      if (location != null) 'location': location,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (zipCode != null) 'zip_code': zipCode,
      if (metadata != null) 'metadata': metadata,
    };
  }

  TrackingUpdate copyWith({
    String? id,
    String? status,
    String? description,
    DateTime? timestamp,
    String? location,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    Map<String, dynamic>? metadata,
  }) {
    return TrackingUpdate(
      id: id ?? this.id,
      status: status ?? this.status,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      metadata: metadata ?? this.metadata,
    );
  }

  String get fullLocation {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }

  @override
  String toString() {
    return 'TrackingUpdate(id: $id, status: $status, description: $description, timestamp: $timestamp, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackingUpdate &&
        other.id == id &&
        other.status == status &&
        other.description == description &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, status, description, timestamp);
  }
}