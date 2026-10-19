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
    
    // 1. Current Condition Alerts
    if (current.rain != null && current.rain! > 0.5) {
      alerts.add(WeatherAlert(
        id: 'rain_current_${current.locationName}',
        type: AlertType.rain,
        titleKey: 'alert_rain_title',
        descriptionKey: 'alert_rain_desc',
        customTitle: '🌧️ Rainy Weather Active Today',
        customDescription: 'Rainfall is active in ${current.locationName} (${current.rain!.toStringAsFixed(1)} mm). Postpone chemical spraying and check water channels.',
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
        customTitle: '☀️ Extreme Heat Stress Alert (${current.temperature.round()}°C)',
        customDescription: 'Intense heat today. Provide timely light irrigation in early morning or late evening to protect crops from scorching.',
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
        customTitle: '💨 Strong Gusty Winds Alert (${current.windSpeed!.round()} km/h)',
        customDescription: 'High wind velocity detected. Delay foliar fertilizer spraying and stake tall crops (Banana, Sugarcane, Maize).',
        severity: AlertSeverity.attention,
        timestamp: now,
      ));
    }

    // 2. Tomorrow's Weather Alert
    if (forecast.length > 1) {
      final tomorrow = forecast[1];
      final tomorrowRain = tomorrow.precipitation ?? 0.0;
      final tomorrowMax = tomorrow.maxTemperature.round();
      final tomorrowMin = tomorrow.minTemperature.round();
      final tomorrowCond = tomorrow.condition;

      String tomTitle;
      String tomDesc;
      AlertSeverity tomSev = AlertSeverity.information;

      if (tomorrowRain >= 5.0) {
        tomTitle = '🌧️ Tomorrow Weather Alert: Rain Expected';
        tomDesc = 'Tomorrow in ${current.locationName}: $tomorrowCond with approx ${tomorrowRain.toStringAsFixed(1)} mm rainfall expected ($tomorrowMax°C / $tomorrowMin°C). Avoid harvesting and cover grain piles.';
        tomSev = AlertSeverity.important;
      } else if (tomorrowMax >= 36) {
        tomTitle = '☀️ Tomorrow Weather Alert: High Heat';
        tomDesc = 'Tomorrow in ${current.locationName}: High heat of $tomorrowMax°C anticipated. Plan field irrigation early.';
        tomSev = AlertSeverity.attention;
      } else {
        tomTitle = '🌤️ Tomorrow Weather Forecast: $tomorrowCond';
        tomDesc = 'Tomorrow in ${current.locationName}: $tomorrowCond ($tomorrowMax°C / $tomorrowMin°C), rain chance ${tomorrowRain.toStringAsFixed(1)} mm. Conditions favorable for normal farming.';
        tomSev = AlertSeverity.information;
      }

      alerts.add(WeatherAlert(
        id: 'tomorrow_forecast_${current.locationName}_${tomorrow.date.toIso8601String().split('T')[0]}',
        type: tomorrowRain >= 5.0 ? AlertType.rain : (tomorrowMax >= 36 ? AlertType.highTemperature : AlertType.temperatureChange),
        titleKey: 'alert_tomorrow_title',
        descriptionKey: 'alert_tomorrow_desc',
        customTitle: tomTitle,
        customDescription: tomDesc,
        severity: tomSev,
        timestamp: now,
        metadata: {'date': tomorrow.date},
      ));
    }

    // 3. Day After Tomorrow (Day 2) Weather Alert
    if (forecast.length > 2) {
      final dayAfter = forecast[2];
      final dayRain = dayAfter.precipitation ?? 0.0;
      final dayMax = dayAfter.maxTemperature.round();
      final dayMin = dayAfter.minTemperature.round();

      if (dayRain >= 5.0 || dayMax >= 36) {
        alerts.add(WeatherAlert(
          id: 'dayafter_forecast_${current.locationName}_${dayAfter.date.toIso8601String().split('T')[0]}',
          type: dayRain >= 5.0 ? AlertType.rain : AlertType.highTemperature,
          titleKey: 'alert_dayafter_title',
          descriptionKey: 'alert_dayafter_desc',
          customTitle: dayRain >= 5.0 ? '🌧️ Day-After-Tomorrow Weather Alert: Rain' : '☀️ Day-After-Tomorrow Weather: High Temperature',
          customDescription: 'In 2 days: ${dayAfter.condition} ($dayMax°C / $dayMin°C) with ${dayRain.toStringAsFixed(1)} mm expected rain. Plan farm labor accordingly.',
          severity: dayRain >= 10.0 ? AlertSeverity.important : AlertSeverity.attention,
          timestamp: now,
          metadata: {'date': dayAfter.date},
        ));
      }
    }

    // Check Temperature Change
    if (forecast.length >= 2) {
      final diff = (forecast[1].maxTemperature - forecast[0].maxTemperature).abs();
      if (diff >= tempChangeThreshold) {
        alerts.add(WeatherAlert(
          id: 'temp_change_${current.locationName}_${forecast[0].date.toIso8601String()}',
          type: AlertType.temperatureChange,
          titleKey: 'alert_temp_change_title',
          descriptionKey: 'alert_temp_change_desc',
          customTitle: '🌡️ Significant Temperature Shift Expected',
          customDescription: 'A difference of ${diff.round()}°C between today and tomorrow. Watch young seedlings and pest occurrences.',
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
