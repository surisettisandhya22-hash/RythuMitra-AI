enum AlertPriority {
  important, // Overdue reminders, etc
  upcoming,  // Upcoming reminders
  information, // General recent activities
}

enum AlertType {
  reminder,
  activity,
  crop,
  financial,
  task,
}

class FarmAlert {
  final String id;
  final AlertType type;
  final AlertPriority priority;
  final String title;
  final String description;
  final String sourceId;
  final DateTime createdAt;
  bool isRead;

  FarmAlert({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.sourceId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'priority': priority.toString(),
      'title': title,
      'description': description,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory FarmAlert.fromJson(Map<String, dynamic> json) {
    return FarmAlert(
      id: json['id'],
      type: AlertType.values.firstWhere((e) => e.toString() == json['type']),
      priority: AlertPriority.values.firstWhere((e) => e.toString() == json['priority']),
      title: json['title'],
      description: json['description'],
      sourceId: json['sourceId'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );
  }
}
