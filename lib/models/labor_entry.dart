// This file defines the LaborEntry model, which represents a single labor entry associated with a project.
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

  // The copyWith method allows creating a modified copy of the LaborEntry instance.
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

// The toMap method converts the LaborEntry instance into a Map<String, dynamic> for easy storage and retrieval.
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
// The fromMap factory constructor creates a LaborEntry instance from a Map<String, dynamic>, handling various data types for date and numeric fields.
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

// The _doubleFromMapValue method is a helper function that converts various types of numeric representations into a double.
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
