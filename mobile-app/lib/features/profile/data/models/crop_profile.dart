class CropProfile {
  final String id;
  final String cropName;
  final String? variety;
  final double? area;
  final String? unit;
  final String? season;
  final String? cropCategory;
  final String? plantingDate;
  final String? expectedHarvestDate;
  final String? growthStage;
  final String? status;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String syncStatus;

  CropProfile({
    required this.id,
    required this.cropName,
    this.variety,
    this.area,
    this.unit,
    this.season,
    this.cropCategory,
    this.plantingDate,
    this.expectedHarvestDate,
    this.growthStage,
    this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropName': cropName,
      'variety': variety,
      'area': area,
      'unit': unit,
      'season': season,
      'cropCategory': cropCategory,
      'plantingDate': plantingDate,
      'expectedHarvestDate': expectedHarvestDate,
      'growthStage': growthStage,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
    };
  }

  factory CropProfile.fromJson(Map<String, dynamic> json) {
    return CropProfile(
      id: json['id'] as String,
      cropName: json['cropName'] as String,
      variety: json['variety'] as String?,
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
      unit: json['unit'] as String?,
      season: json['season'] as String?,
      cropCategory: json['cropCategory'] as String?,
      plantingDate: json['plantingDate'] as String?,
      expectedHarvestDate: json['expectedHarvestDate'] as String?,
      growthStage: json['growthStage'] as String?,
      status: json['status'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }

  CropProfile copyWith({
    String? id,
    String? cropName,
    String? variety,
    double? area,
    String? unit,
    String? season,
    String? cropCategory,
    String? plantingDate,
    String? expectedHarvestDate,
    String? growthStage,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) {
    return CropProfile(
      id: id ?? this.id,
      cropName: cropName ?? this.cropName,
      variety: variety ?? this.variety,
      area: area ?? this.area,
      unit: unit ?? this.unit,
      season: season ?? this.season,
      cropCategory: cropCategory ?? this.cropCategory,
      plantingDate: plantingDate ?? this.plantingDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
      growthStage: growthStage ?? this.growthStage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
