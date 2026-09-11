class FarmActivity {
  final String id;
  final String activityType;
  final String? cropId;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  FarmActivity({
    required this.id,
    required this.activityType,
    this.cropId,
    required this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType,
      'cropId': cropId,
      'date': date.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  factory FarmActivity.fromJson(Map<String, dynamic> json) {
    return FarmActivity(
      id: json['id'] as String,
      activityType: json['activityType'] as String,
      cropId: json['cropId'] as String?,
      date: DateTime.parse(json['date']),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }
}
