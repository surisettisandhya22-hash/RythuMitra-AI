import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/weather_alert.dart';

class AlertStorageService {
  static const String _keyAlerts = 'weather_alerts';

  late SharedPreferences _prefs;
  final ValueNotifier<List<WeatherAlert>> alertsNotifier = ValueNotifier([]);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAlerts();
  }

  void _loadAlerts() {
    final String? alertsJson = _prefs.getString(_keyAlerts);
    if (alertsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(alertsJson);
        final alerts = decoded.map((e) => WeatherAlert.fromJson(e)).toList();
        
        // Remove old alerts (e.g., older than 3 days)
        final now = DateTime.now();
        alerts.removeWhere((a) => now.difference(a.timestamp).inDays > 3);
        
        alertsNotifier.value = alerts;
        _saveAlerts(alerts); // Save cleaned list
      } catch (e) {
        debugPrint('Error loading alerts: $e');
        alertsNotifier.value = [];
      }
    }
  }

  Future<void> _saveAlerts(List<WeatherAlert> alerts) async {
    final String encoded = jsonEncode(alerts.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyAlerts, encoded);
    alertsNotifier.value = List.from(alerts);
  }

  Future<void> addOrUpdateAlert(WeatherAlert alert) async {
    final alerts = List<WeatherAlert>.from(alertsNotifier.value);
    final index = alerts.indexWhere((a) => a.id == alert.id);
    
    if (index >= 0) {
      alerts[index] = alert;
    } else {
      alerts.add(alert);
    }
    
    await _saveAlerts(alerts);
  }

  Future<void> dismissAlert(String id) async {
    final alerts = List<WeatherAlert>.from(alertsNotifier.value);
    final index = alerts.indexWhere((a) => a.id == id);
    
    if (index >= 0) {
      alerts[index].isDismissed = true;
      await _saveAlerts(alerts);
    }
  }

  List<WeatherAlert> getActiveAlerts() {
    return alertsNotifier.value.where((a) => !a.isDismissed).toList();
  }
}
