class TreatmentOptions {
  final List<String> organicTreatment;
  final List<String> chemicalTreatment;
  final List<String> preventiveMeasures;

  TreatmentOptions({
    required this.organicTreatment,
    required this.chemicalTreatment,
    required this.preventiveMeasures,
  });

  Map<String, dynamic> toJson() {
    return {
      'organicTreatment': organicTreatment,
      'chemicalTreatment': chemicalTreatment,
      'preventiveMeasures': preventiveMeasures,
    };
  }

  factory TreatmentOptions.fromJson(Map<String, dynamic> json) {
    return TreatmentOptions(
      organicTreatment: List<String>.from(json['organicTreatment'] ?? []),
      chemicalTreatment: List<String>.from(json['chemicalTreatment'] ?? []),
      preventiveMeasures: List<String>.from(json['preventiveMeasures'] ?? []),
    );
  }
}

class ScanResult {
  final String id;
  final String? cropId;
  final String? cropName;
  final String? severityLevel;
  final String? confidenceScore;
  final String? description;
  final String date;
  final String summary;
  final List<String> possibleIssues;
  final List<String> visibleSymptoms;
  final TreatmentOptions? treatmentOptions;
  final List<String> recommendedNextSteps;
  final String whenToSeekExpertHelp;

  ScanResult({
    required this.id,
    this.cropId,
    this.cropName,
    this.severityLevel,
    this.confidenceScore,
    this.description,
    required this.date,
    required this.summary,
    required this.possibleIssues,
    required this.visibleSymptoms,
    this.treatmentOptions,
    required this.recommendedNextSteps,
    required this.whenToSeekExpertHelp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'cropName': cropName,
      'severityLevel': severityLevel,
      'confidenceScore': confidenceScore,
      'description': description,
      'date': date,
      'summary': summary,
      'possibleIssues': possibleIssues,
      'visibleSymptoms': visibleSymptoms,
      'treatmentOptions': treatmentOptions?.toJson(),
      'recommendedNextSteps': recommendedNextSteps,
      'whenToSeekExpertHelp': whenToSeekExpertHelp,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cropId: json['cropId'] as String?,
      cropName: json['cropName'] as String?,
      severityLevel: json['severityLevel'] as String? ?? 'Moderate',
      confidenceScore: json['confidenceScore'] as String? ?? '85%',
      description: json['description'] as String?,
      date: json['date'] as String? ?? DateTime.now().toIso8601String(),
      summary: json['summary'] as String? ?? '',
      possibleIssues: List<String>.from(json['possibleIssues'] ?? []),
      visibleSymptoms: List<String>.from(json['visibleSymptoms'] ?? []),
      treatmentOptions: json['treatmentOptions'] != null
          ? TreatmentOptions.fromJson(json['treatmentOptions'] as Map<String, dynamic>)
          : null,
      recommendedNextSteps: List<String>.from(json['recommendedNextSteps'] ?? []),
      whenToSeekExpertHelp: json['whenToSeekExpertHelp'] as String? ?? '',
    );
  }
}
