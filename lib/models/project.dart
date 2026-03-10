// This file defines the Project model, which represents a project with its associated details such as name, owner, client, address, and timestamps for creation and updates.
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

// The copyWith method allows creating a modified copy of the Project instance, with options to clear nullable fields.
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

// The toMap method converts the Project instance into a Map<String, dynamic> for easy storage and retrieval, while the fromMap factory constructor creates a Project instance from a Map<String, dynamic>, handling various data types for date fields.
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

// The fromMap factory constructor creates a Project instance from a Map<String, dynamic>, handling various data types for date fields.
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

// The _dateTimeFromMapValue method is a helper function that converts various types of date representations into a DateTime object.
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
        // Ignore unsupported date types and fail below with a clear error.
      }
    }

    throw ArgumentError('Invalid date value: $value');
  }
}
