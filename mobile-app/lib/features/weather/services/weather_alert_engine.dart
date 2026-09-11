import '../domain/models/weather_data.dart';
import '../domain/models/weather_forecast.dart';
import '../domain/models/weather_alert.dart';

class WeatherAlertEngine {
  // Thresholds
  static const double rainThreshold = 5.0; // mm
  static const double highTempThreshold = 35.0; // Celsius
  static const double strongWindThreshold = 30.0; // km/h
  static const double tempChangeThreshold = 10.0; // Celsius difference between days

  List<WeatherAlert> generateAlerts(WeatherData current, List<WeatherForecast> forecast) {
    List<WeatherAlert> alerts = [];
    final now = DateTime.now();
    
    // Check Current Conditions
    if (current.rain != null && current.rain! > rainThreshold) {
      alerts.add(WeatherAlert(
        id: 'rain_current_${current.locationName}',
        type: AlertType.rain,
        titleKey: 'alert_rain_title',
        descriptionKey: 'alert_rain_desc',
        severity: AlertSeverity.important,
        timestamp: now,
      ));
    }

    if (current.temperature >= highTempThreshold) {
      alerts.add(WeatherAlert(
        id: 'temp_current_${current.locationName}',
        type: AlertType.highTemperature,
        titleKey: 'alert_temp_title',
        descriptionKey: 'alert_temp_desc',
        severity: AlertSeverity.attention,
        timestamp: now,
      ));
    }

    if (current.windSpeed != null && current.windSpeed! >= strongWindThreshold) {
      alerts.add(WeatherAlert(
        id: 'wind_current_${current.locationName}',
        type: AlertType.strongWind,
        titleKey: 'alert_wind_title',
        descriptionKey: 'alert_wind_desc',
        severity: AlertSeverity.attention,
        timestamp: now,
      ));
    }

    // Check Forecast (Next 2 days)
    final checkDays = forecast.take(2).toList();
    for (int i = 0; i < checkDays.length; i++) {
      final day = checkDays[i];
      final dayIdStr = day.date.toIso8601String().split('T')[0];
      
      if (day.precipitation != null && day.precipitation! > rainThreshold) {
        alerts.add(WeatherAlert(
          id: 'rain_forecast_${current.locationName}_$dayIdStr',
          type: AlertType.rain,
          titleKey: 'alert_rain_forecast_title',
          descriptionKey: 'alert_rain_forecast_desc',
          severity: AlertSeverity.information,
          timestamp: now,
          metadata: {'date': day.date},
        ));
      }

      if (day.maxTemperature >= highTempThreshold) {
        alerts.add(WeatherAlert(
          id: 'temp_forecast_${current.locationName}_$dayIdStr',
          type: AlertType.highTemperature,
          titleKey: 'alert_temp_forecast_title',
          descriptionKey: 'alert_temp_forecast_desc',
          severity: AlertSeverity.attention,
          timestamp: now,
          metadata: {'date': day.date},
        ));
      }
    }
    
    // Check Temperature Change
    if (checkDays.length >= 2) {
      final diff = (checkDays[1].maxTemperature - checkDays[0].maxTemperature).abs();
      if (diff >= tempChangeThreshold) {
        alerts.add(WeatherAlert(
          id: 'temp_change_${current.locationName}_${checkDays[0].date.toIso8601String()}',
          type: AlertType.temperatureChange,
          titleKey: 'alert_temp_change_title',
          descriptionKey: 'alert_temp_change_desc',
          severity: AlertSeverity.information,
          timestamp: now,
        ));
      }
    }

    // Deduplicate by ID
    final Map<String, WeatherAlert> uniqueAlerts = {};
    for (var alert in alerts) {
      uniqueAlerts[alert.id] = alert;
    }

    return uniqueAlerts.values.toList();
  }
}
