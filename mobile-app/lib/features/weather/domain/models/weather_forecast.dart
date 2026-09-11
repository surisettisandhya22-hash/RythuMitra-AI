class WeatherForecast {
  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final String condition;
  final double? precipitation;

  WeatherForecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.condition,
    this.precipitation,
  });
}
