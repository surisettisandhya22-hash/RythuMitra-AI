class CropStageTask {
  final String id;
  final int dayOffset;
  final String title;
  final String description;
  final String category; // 'fertilizer', 'irrigation', 'pest_control', 'field_care'
  final String priority; // 'high', 'medium', 'low'
  bool completed;

  CropStageTask({
    required this.id,
    required this.dayOffset,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.completed = false,
  });

  factory CropStageTask.fromJson(Map<String, dynamic> json) {
    return CropStageTask(
      id: json['id'] as String? ?? '',
      dayOffset: json['day_offset'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'field_care',
      priority: json['priority'] as String? ?? 'medium',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day_offset': dayOffset,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'completed': completed,
    };
  }
}

class CropGrowthStage {
  final String stageName;
  final String stageKey;
  final String dayRange;
  final String icon;
  final String summary;
  final List<CropStageTask> tasks;

  CropGrowthStage({
    required this.stageName,
    required this.stageKey,
    required this.dayRange,
    required this.icon,
    required this.summary,
    required this.tasks,
  });

  factory CropGrowthStage.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? [];
    return CropGrowthStage(
      stageName: json['stage_name'] as String? ?? '',
      stageKey: json['stage_key'] as String? ?? '',
      dayRange: json['day_range'] as String? ?? '',
      icon: json['icon'] as String? ?? '🌱',
      summary: json['summary'] as String? ?? '',
      tasks: rawTasks.map((t) => CropStageTask.fromJson(t as Map<String, dynamic>)).toList(),
    );
  }
}

class CropCalendarPlan {
  final String cropName;
  final String cropVariety;
  final String sowingDate;
  final int totalDurationDays;
  final int currentDay;
  final String currentStage;
  final List<CropGrowthStage> stages;
  final List<String> smartTips;

  CropCalendarPlan({
    required this.cropName,
    required this.cropVariety,
    required this.sowingDate,
    required this.totalDurationDays,
    required this.currentDay,
    required this.currentStage,
    required this.stages,
    required this.smartTips,
  });

  factory CropCalendarPlan.fromJson(Map<String, dynamic> json) {
    final rawStages = json['stages'] as List<dynamic>? ?? [];
    final rawTips = json['smart_tips'] as List<dynamic>? ?? [];

    return CropCalendarPlan(
      cropName: json['crop_name'] as String? ?? 'Crop',
      cropVariety: json['crop_variety'] as String? ?? 'Standard',
      sowingDate: json['sowing_date'] as String? ?? '',
      totalDurationDays: json['total_duration_days'] as int? ?? 120,
      currentDay: json['current_day'] as int? ?? 1,
      currentStage: json['current_stage'] as String? ?? '',
      stages: rawStages.map((s) => CropGrowthStage.fromJson(s as Map<String, dynamic>)).toList(),
      smartTips: rawTips.map((t) => t.toString()).toList(),
    );
  }
}
