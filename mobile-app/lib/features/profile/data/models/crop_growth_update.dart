class CropGrowthUpdate {
  final String id;
  final String cropId;
  final DateTime date;
  final String growthStage;
  final String? notes;

  CropGrowthUpdate({
    required this.id,
    required this.cropId,
    required this.date,
    required this.growthStage,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'date': date.toIso8601String(),
      'growthStage': growthStage,
      'notes': notes,
    };
  }

  factory CropGrowthUpdate.fromJson(Map<String, dynamic> json) {
    return CropGrowthUpdate(
      id: json['id'] as String,
      cropId: json['cropId'] as String,
      date: DateTime.parse(json['date']),
      growthStage: json['growthStage'] as String,
      notes: json['notes'] as String?,
    );
  }
}
