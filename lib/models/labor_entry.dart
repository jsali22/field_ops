class LaborEntry {
  const LaborEntry({
    required this.id,
    required this.projectId,
    required this.date,
    required this.roleTask,
    required this.hours,
    required this.hourlyRate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final DateTime date;
  final String roleTask;
  final double hours;
  final double hourlyRate;
  final String? notes;
  final DateTime createdAt;

  // `clearNotes` is used when an edit intentionally removes saved notes.
  LaborEntry copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    String? roleTask,
    double? hours,
    double? hourlyRate,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
  }) {
    return LaborEntry(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      roleTask: roleTask ?? this.roleTask,
      hours: hours ?? this.hours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'projectId': projectId,
      'date': date,
      'roleTask': roleTask,
      'hours': hours,
      'hourlyRate': hourlyRate,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  // Accepts common Firestore/runtime types so the model can be rebuilt from
  // database snapshots without extra parsing in the service layer.
  factory LaborEntry.fromMap(Map<String, dynamic> map) {
    return LaborEntry(
      id: map['id'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      date: _dateTimeFromMapValue(map['date']),
      roleTask: map['roleTask'] as String? ?? '',
      hours: _doubleFromMapValue(map['hours']),
      hourlyRate: _doubleFromMapValue(map['hourlyRate']),
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
