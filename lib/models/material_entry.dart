class MaterialEntry {
  const MaterialEntry({
    required this.id,
    required this.projectId,
    required this.date,
    required this.name,
    required this.quantity,
    required this.unitCost,
    this.vendor,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final DateTime date;
  final String name;
  final double quantity;
  final double unitCost;
  final String? vendor;
  final String? notes;
  final DateTime createdAt;

  // `clearVendor` and `clearNotes` are used when edits intentionally remove
  // optional fields.
  MaterialEntry copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    String? name,
    double? quantity,
    double? unitCost,
    String? vendor,
    String? notes,
    DateTime? createdAt,
    bool clearVendor = false,
    bool clearNotes = false,
  }) {
    return MaterialEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      vendor: clearVendor ? null : (vendor ?? this.vendor),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'date': date,
      'name': name,
      'quantity': quantity,
      'unitCost': unitCost,
      'vendor': vendor,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  // Accepts common Firestore/runtime types so the model can be rebuilt from
  // database snapshots without extra parsing in the service layer.
  factory MaterialEntry.fromMap(Map<String, dynamic> map) {
    return MaterialEntry(
      id: map['id'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      date: _dateTimeFromMapValue(map['date']),
      name: map['name'] as String? ?? '',
      quantity: _doubleFromMapValue(map['quantity']),
      unitCost: _doubleFromMapValue(map['unitCost']),
      vendor: map['vendor'] as String?,
      notes: map['notes'] as String?,
      createdAt: _dateTimeFromMapValue(map['createdAt']),
    );
  }

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

  // Firestore numbers can arrive as either int or double, so this helper keeps
  // that conversion in one place.
  static double _doubleFromMapValue(dynamic value) {
    if (value is int) {
      return value.toDouble();
    }

    if (value is double) {
      return value;
    }

    if (value is String) {
      return double.parse(value);
    }

    throw ArgumentError('Invalid numeric value: $value');
  }
}
