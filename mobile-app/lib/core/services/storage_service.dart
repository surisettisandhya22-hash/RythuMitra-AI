import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keySelectedLanguage = 'selectedLanguage';
  static const String _keyHasCompletedLanguageSelection = 'hasCompletedLanguageSelection';
  static const String _keyIsLoggedIn = 'isLoggedIn';

  late SharedPreferences _prefs;
  late final ValueNotifier<String> languageNotifier;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    languageNotifier = ValueNotifier<String>(getSelectedLanguage() ?? 'en');
  }

  Future<void> saveSelectedLanguage(String languageCode) async {
    await _prefs.setString(_keySelectedLanguage, languageCode);
    languageNotifier.value = languageCode;
  }

  String? getSelectedLanguage() {
    return _prefs.getString(_keySelectedLanguage);
  }

  Future<void> setHasCompletedLanguageSelection(bool completed) async {
    await _prefs.setBool(_keyHasCompletedLanguageSelection, completed);
  }

  bool hasCompletedLanguageSelection() {
    return _prefs.getBool(_keyHasCompletedLanguageSelection) ?? false;
  }

  Future<void> setLoggedIn(bool loggedIn) async {
    await _prefs.setBool(_keyIsLoggedIn, loggedIn);
  }

  bool isLoggedIn() {
    return _prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setAutoSpeakEnabled(bool enabled) async {
    await _prefs.setBool('autoSpeakEnabled', enabled);
  }

  bool getAutoSpeakEnabled() {
    return _prefs.getBool('autoSpeakEnabled') ?? true;
  }

  Future<void> setSpeechSpeed(double speed) async {
    await _prefs.setDouble('speechSpeed', speed);
  }

  double getSpeechSpeed() {
    return _prefs.getDouble('speechSpeed') ?? 0.5;
  }

  // --- Alerts State Tracking ---
  List<String> getReadAlertIds() {
    return _prefs.getStringList('readAlertIds') ?? [];
  }

  Future<void> addReadAlertId(String alertId) async {
    final current = getReadAlertIds();
    if (!current.contains(alertId)) {
      current.add(alertId);
      await _prefs.setStringList('readAlertIds', current);
    }
  }

  List<String> getDismissedAlertIds() {
    return _prefs.getStringList('dismissedAlertIds') ?? [];
  }

  Future<void> addDismissedAlertId(String alertId) async {
    final current = getDismissedAlertIds();
    if (!current.contains(alertId)) {
      current.add(alertId);
      await _prefs.setStringList('dismissedAlertIds', current);
    }
  }
}
