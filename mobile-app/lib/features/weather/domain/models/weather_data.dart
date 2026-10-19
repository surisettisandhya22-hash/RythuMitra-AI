class WeatherData {
  final double temperature;
  final double? feelsLike;
  final String condition;
  final double? humidity;
  final double? windSpeed;
  final double? rain;
  final String? airQuality;
  final double? uvIndex;
  final DateTime lastUpdated;
  final String locationName;

  WeatherData({
    required this.temperature,
    this.feelsLike,
    required this.condition,
    this.humidity,
    this.windSpeed,
    this.rain,
    this.airQuality,
    this.uvIndex,
    required this.lastUpdated,
    required this.locationName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String locationName) {
    final current = json['current_weather'] ?? json['current'] ?? json;
    
    return WeatherData(
      temperature: (current['temperature'] ?? 0.0).toDouble(),
      feelsLike: current['feelsLike'] != null ? (current['feelsLike']).toDouble() : null,
      condition: current['condition'] is String 
          ? current['condition'] 
          : _parseCondition(current['weathercode'] ?? current['weather_code']),
      humidity: current['relative_humidity'] != null 
          ? (current['relative_humidity']).toDouble() 
          : (current['humidity'] != null ? (current['humidity']).toDouble() : null),
      windSpeed: current['windspeed'] != null 
          ? (current['windspeed']).toDouble() 
          : (current['windSpeed'] != null ? (current['windSpeed']).toDouble() : null),
      rain: current['precipitation'] != null 
          ? (current['precipitation']).toDouble() 
          : (current['rain'] != null ? (current['rain']).toDouble() : null),
      airQuality: current['airQuality'] as String?,
      uvIndex: current['uvIndex'] != null ? (current['uvIndex']).toDouble() : null,
      lastUpdated: DateTime.now(),
      locationName: locationName,
    );
  }

  static String _parseCondition(int? code) {
    if (code == null) return 'Unknown';
    if (code == 0) return 'Clear sky';
    if (code == 1 || code == 2 || code == 3) return 'Partly cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Cloudy';
  }
}
