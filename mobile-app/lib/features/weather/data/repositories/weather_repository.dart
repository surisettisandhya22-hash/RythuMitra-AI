import 'package:geolocator/geolocator.dart';
import '../../domain/models/weather_data.dart';
import '../../domain/models/weather_forecast.dart';
import '../../services/weather_service.dart';

class WeatherRepository {
  final WeatherService _weatherService = WeatherService();
  WeatherData? _cachedWeatherData;
  List<WeatherForecast>? _cachedForecast;

  Future<void> _fetchAndCacheWeather(String locationPreference, {String? customLocation}) async {
    double? lat;
    double? lon;
    String? locationName;

    if (locationPreference == 'current') {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Unable to access your location.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Unable to access your location.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Unable to access your location.');
      }

      Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
      lat = position.latitude;
      lon = position.longitude;
    } else if (customLocation != null && customLocation.isNotEmpty) {
      locationName = customLocation;
    } else {
      throw Exception('No valid location provided.');
    }

    final data = await _weatherService.fetchWeather(
      lat: lat,
      lon: lon,
      locationName: locationName,
    );

    _cachedWeatherData = WeatherData(
      temperature: (data['temperature'] as num).toDouble(),
      condition: data['condition'],
      humidity: (data['humidity'] as num).toDouble(),
      windSpeed: (data['windSpeed'] as num).toDouble(),
      rain: (data['rain'] as num).toDouble(),
      lastUpdated: DateTime.parse(data['timestamp']),
      locationName: data['location'],
    );

    _cachedForecast = (data['forecast'] as List).map((f) => WeatherForecast(
      date: DateTime.parse(f['date']),
      minTemperature: (f['minTemperature'] as num).toDouble(),
      maxTemperature: (f['maxTemperature'] as num).toDouble(),
      condition: f['condition'],
      precipitation: (f['precipitation'] as num).toDouble(),
    )).toList();
  }

  Future<WeatherData> getWeather(String locationPreference, {String? customLocation, bool forceRefresh = false}) async {
    if (_cachedWeatherData == null || forceRefresh) {
      await _fetchAndCacheWeather(locationPreference, customLocation: customLocation);
    }
    return _cachedWeatherData!;
  }

  Future<List<WeatherForecast>> getForecast(String locationPreference, {String? customLocation, bool forceRefresh = false}) async {
    if (_cachedForecast == null || forceRefresh) {
      await _fetchAndCacheWeather(locationPreference, customLocation: customLocation);
    }
    return _cachedForecast!;
  }

  WeatherData? get cachedWeather => _cachedWeatherData;
  List<WeatherForecast>? get cachedForecast => _cachedForecast;
}
