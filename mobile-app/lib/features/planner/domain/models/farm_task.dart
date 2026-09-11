
class FarmTask {
  final String id;
  final String title;
  final DateTime date;
  final bool hasTime;
  final String? cropId;
  final String? notes;
  bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  DateTime? completedAt;

  FarmTask({
    required this.id,
    required this.title,
    required this.date,
    this.hasTime = false,
    this.cropId,
    this.notes,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory FarmTask.fromJson(Map<String, dynamic> json) {
    return FarmTask(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      hasTime: json['hasTime'] ?? false,
      cropId: json['cropId'],
      notes: json['notes'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hasTime': hasTime,
      'cropId': cropId,
      'notes': notes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
