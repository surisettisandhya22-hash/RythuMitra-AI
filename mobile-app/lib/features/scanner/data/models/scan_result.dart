class ScanResult {
  final String id;
  final String? cropId;
  final String? cropName;
  final String? description;
  final String date;
  final String summary;
  final List<String> possibleIssues;
  final List<String> visibleSymptoms;
  final List<String> recommendedNextSteps;
  final String whenToSeekExpertHelp;

  ScanResult({
    required this.id,
    this.cropId,
    this.cropName,
    this.description,
    required this.date,
    required this.summary,
    required this.possibleIssues,
    required this.visibleSymptoms,
    required this.recommendedNextSteps,
    required this.whenToSeekExpertHelp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'cropName': cropName,
      'description': description,
      'date': date,
      'summary': summary,
      'possibleIssues': possibleIssues,
      'visibleSymptoms': visibleSymptoms,
      'recommendedNextSteps': recommendedNextSteps,
      'whenToSeekExpertHelp': whenToSeekExpertHelp,
    };
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] as String,
      cropId: json['cropId'] as String?,
      cropName: json['cropName'] as String?,
      description: json['description'] as String?,
      date: json['date'] as String,
      summary: json['summary'] as String,
      possibleIssues: List<String>.from(json['possibleIssues'] ?? []),
      visibleSymptoms: List<String>.from(json['visibleSymptoms'] ?? []),
      recommendedNextSteps: List<String>.from(json['recommendedNextSteps'] ?? []),
      whenToSeekExpertHelp: json['whenToSeekExpertHelp'] as String,
    );
  }
}
