enum AlertSeverity {
  information,
  attention,
  important,
}

enum AlertType {
  rain,
  highTemperature,
  strongWind,
  temperatureChange,
}

class WeatherAlert {
  final String id;
  final AlertType type;
  final String titleKey;
  final String descriptionKey;
  final String? customTitle;
  final String? customDescription;
  final AlertSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  bool isDismissed;

  WeatherAlert({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.descriptionKey,
    this.customTitle,
    this.customDescription,
    required this.severity,
    required this.timestamp,
    this.metadata = const {},
    this.isDismissed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'customTitle': customTitle,
      'customDescription': customDescription,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'isDismissed': isDismissed,
    };
  }

  factory WeatherAlert.fromJson(Map<String, dynamic> json) {
    return WeatherAlert(
      id: json['id'] as String,
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      titleKey: json['titleKey'] as String,
      descriptionKey: json['descriptionKey'] as String,
      customTitle: json['customTitle'] as String?,
      customDescription: json['customDescription'] as String?,
      severity: AlertSeverity.values.firstWhere((e) => e.name == json['severity']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isDismissed: json['isDismissed'] as bool? ?? false,
    );
  }
}
