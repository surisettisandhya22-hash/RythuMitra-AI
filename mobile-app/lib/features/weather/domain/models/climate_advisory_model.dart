class SprayingAdviceModel {
  final bool isFavorable;
  final String statusText;
  final String reason;

  SprayingAdviceModel({
    required this.isFavorable,
    required this.statusText,
    required this.reason,
  });

  factory SprayingAdviceModel.fromJson(Map<String, dynamic> json) {
    return SprayingAdviceModel(
      isFavorable: json['isFavorable'] ?? false,
      statusText: json['statusText'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class IrrigationAdviceModel {
  final bool shouldIrrigate;
  final String adviceText;
  final String? expectedRainAlert;

  IrrigationAdviceModel({
    required this.shouldIrrigate,
    required this.adviceText,
    this.expectedRainAlert,
  });

  factory IrrigationAdviceModel.fromJson(Map<String, dynamic> json) {
    return IrrigationAdviceModel(
      shouldIrrigate: json['shouldIrrigate'] ?? true,
      adviceText: json['adviceText'] ?? '',
      expectedRainAlert: json['expectedRainAlert'],
    );
  }
}

class SevereAlertModel {
  final String severity;
  final String title;
  final String description;

  SevereAlertModel({
    required this.severity,
    required this.title,
    required this.description,
  });

  factory SevereAlertModel.fromJson(Map<String, dynamic> json) {
    return SevereAlertModel(
      severity: json['severity'] ?? 'Moderate',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class ClimateAdvisoryModel {
  final String location;
  final String? crop;
  final String summary;
  final SprayingAdviceModel sprayingWindow;
  final IrrigationAdviceModel irrigationAdvice;
  final String harvestingAdvice;
  final String pestDiseaseRisk;
  final List<SevereAlertModel> severeAlerts;

  ClimateAdvisoryModel({
    required this.location,
    this.crop,
    required this.summary,
    required this.sprayingWindow,
    required this.irrigationAdvice,
    required this.harvestingAdvice,
    required this.pestDiseaseRisk,
    required this.severeAlerts,
  });

  factory ClimateAdvisoryModel.fromJson(Map<String, dynamic> json) {
    return ClimateAdvisoryModel(
      location: json['location'] ?? '',
      crop: json['crop'],
      summary: json['summary'] ?? '',
      sprayingWindow: SprayingAdviceModel.fromJson(
          json['sprayingWindow'] as Map<String, dynamic>? ?? {}),
      irrigationAdvice: IrrigationAdviceModel.fromJson(
          json['irrigationAdvice'] as Map<String, dynamic>? ?? {}),
      harvestingAdvice: json['harvestingAdvice'] ?? '',
      pestDiseaseRisk: json['pestDiseaseRisk'] ?? '',
      severeAlerts: (json['severeAlerts'] as List<dynamic>? ?? [])
          .map((a) => SevereAlertModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
