class FarmReminder {
  final String id;
  final String title;
  final String? description;
  final String? cropId;
  final DateTime date;
  final bool hasTime;
  bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  FarmReminder({
    required this.id,
    required this.title,
    this.description,
    this.cropId,
    required this.date,
    this.hasTime = false,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  factory FarmReminder.fromJson(Map<String, dynamic> json) {
    return FarmReminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      cropId: json['cropId'],
      date: DateTime.parse(json['date']),
      hasTime: json['hasTime'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      syncStatus: json['syncStatus'] ?? 'local',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cropId': cropId,
      'date': date.toIso8601String(),
      'hasTime': hasTime,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }
}
