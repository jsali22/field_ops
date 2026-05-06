class Project {
  const Project({
    required this.id,
    required this.name,
    required this.ownerUid,
    this.client,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final String? client;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  // `clearClient` and `clearAddress` let edit flows intentionally remove
  // optional fields instead of falling back to previous values.
  Project copyWith({
    String? id,
    String? name,
    String? ownerUid,
    String? client,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearClient = false,
    bool clearAddress = false,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid ?? this.ownerUid,
      client: clearClient ? null : (client ?? this.client),
      address: clearAddress ? null : (address ?? this.address),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'ownerUid': ownerUid,
      'client': client,
      'address': address,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ownerUid: map['ownerUid'] as String? ?? '',
      client: map['client'] as String?,
      address: map['address'] as String?,
      createdAt: _dateTimeFromMapValue(map['createdAt']),
      updatedAt: _dateTimeFromMapValue(map['updatedAt']),
    );
  }

  // Accepts DateTime, epoch values, strings, or Firestore-style timestamps so
  // the model can deserialize cleanly in both app code and database reads.
  static DateTime _dateTimeFromMapValue(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      return DateTime.parse(value);
    }

    if (value != null) {
      try {
        final dynamic converted = (value as dynamic).toDate();
        if (converted is DateTime) {
          return converted;
        }
      } catch (_) {
        // Firestore Timestamp-like values are supported through `toDate()`.
      }
    }

    throw ArgumentError('Invalid date value: $value');
  }
}
