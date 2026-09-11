import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/farm_reminder.dart';
import '../../../core/services/notification_service.dart';

class ReminderStorageService {
  static const String _remindersKey = 'farm_reminders';
  final NotificationService _notificationService = NotificationService();

  Future<void> init({void Function(String?)? onNotificationTap}) async {
    await _notificationService.init(onNotificationTap: onNotificationTap);
  }

  Future<List<FarmReminder>> getReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString(_remindersKey);
    
    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);
      return decoded.map((e) => FarmReminder.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> addReminder(FarmReminder reminder, {bool scheduleNotification = true}) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    await _saveReminders(reminders);

    if (scheduleNotification && !reminder.isCompleted && reminder.date.isAfter(DateTime.now())) {
      try {
        await _notificationService.scheduleReminderNotification(
          id: reminder.id.hashCode,
          title: reminder.title,
          body: reminder.description ?? 'You have a farm reminder.',
          scheduledDate: reminder.date,
        );
      } catch (e) {
        // Notification scheduling failed, but reminder is saved
      }
    }
  }

  Future<void> updateReminder(FarmReminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _saveReminders(reminders);
      
      await _notificationService.cancelNotification(reminder.id.hashCode);
      if (!reminder.isCompleted && reminder.date.isAfter(DateTime.now())) {
        try {
          await _notificationService.scheduleReminderNotification(
            id: reminder.id.hashCode,
            title: reminder.title,
            body: reminder.description ?? 'You have a farm reminder.',
            scheduledDate: reminder.date,
          );
        } catch (e) {
          // Ignore
        }
      }
    }
  }
  
  Future<void> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    await _saveReminders(reminders);
    await _notificationService.cancelNotification(id.hashCode);
  }

  Future<void> _saveReminders(List<FarmReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
    await prefs.setString(_remindersKey, encoded);
  }

  Future<bool> requestNotificationPermission() async {
    return await _notificationService.requestPermission();
  }
}
